mutable struct Backoff
    limit::Int
    @const maxdelay::Int
end

function (backoff::Backoff)()
    limit = backoff.limit
    backoff.limit = min(backoff.maxdelay, 2limit)
    # TODO: don't use TaskLocalRNG
    delay = rand(1:limit)
    spinfor(delay)
end

abstract type BackoffSpinLock <: Lockable end

@enum BackoffSpinLockState LCK_AVAILABLE LCK_HELD

mutable struct NonreentrantBackoffSpinLock <: BackoffSpinLock
    @atomic state::BackoffSpinLockState
    @const _pad::NTuple{7,Int}
    mindelay::Int
    maxdelay::Int
end

NonreentrantBackoffSpinLock(; mindelay = 1, maxdelay = 1000) =
    NonreentrantBackoffSpinLock(LCK_AVAILABLE, pad7(), mindelay, maxdelay)

mutable struct ReentrantBackoffSpinLock <: BackoffSpinLock
    @atomic state::BackoffSpinLockState
    @const _pad1::NTuple{7,Int}
    mindelay::Int
    maxdelay::Int
    @const _pad2::NTuple{7,Int}
    @atomic owner::Union{Nothing,Task}
    count::Int
end

ReentrantBackoffSpinLock(; mindelay = 1, maxdelay = 1000) =
    ReentrantBackoffSpinLock(LCK_AVAILABLE, pad7(), mindelay, maxdelay, pad7(), nothing, 0)

isreentrant(::ReentrantBackoffSpinLock) = true

Base.islocked(lock::BackoffSpinLock) = (@atomic :monotonic lock.state) !== LCK_AVAILABLE

function ConcurrentUtils.try_race_acquire(lock::BackoffSpinLock)
    handle_reentrant_acquire(lock) && return Ok(nothing)
    if !islocked(lock) && (@atomicswap :acquire lock.state = LCK_HELD) === LCK_AVAILABLE
        start_reentrant_acquire(lock)
        return Ok(nothing)
    end
    return Err(NotAcquirableError())
end

function ConcurrentUtils.acquire(
    lock::BackoffSpinLock;
    mindelay = lock.mindelay,
    maxdelay = lock.maxdelay,
)
    handle_reentrant_acquire(lock) && return

    if !islocked(lock) && (@atomicswap :acquire lock.state = LCK_HELD) === LCK_AVAILABLE
        @goto locked
    end

    backoff = Backoff(max(1, mindelay), max(1, maxdelay))
    while true
        while islocked(lock)
            spinloop()
        end
        backoff()
        if (@atomicswap :acquire lock.state = LCK_HELD) === LCK_AVAILABLE
            @goto locked
        end
    end

    @label locked
    start_reentrant_acquire(lock)
    return
end

function ConcurrentUtils.release(lock::BackoffSpinLock)
    handle_reentrant_release(lock) && return
    @atomic :release lock.state = LCK_AVAILABLE
    return
end
