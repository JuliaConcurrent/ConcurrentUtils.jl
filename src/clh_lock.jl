struct IsLocked end

mutable struct LockQueueNode
    @atomic state::Union{IsLocked,Task,Nothing}
    _pad::NTuple{7,Int}

    LockQueueNode(state) = new(state)
end

@inline _islocked(node::LockQueueNode) = (@atomic :monotonic node.state) isa IsLocked

# TODO: Compare it with MCSLock
abstract type CLHLock <: Lockable end

mutable struct NonreentrantCLHLock <: CLHLock
    # TODO: node caching
    @atomic tail::LockQueueNode
    @const _pad::NTuple{7,Int}
    current::LockQueueNode
end

const DUMMY_NODE = LockQueueNode(nothing)

NonreentrantCLHLock() =
    NonreentrantCLHLock(LockQueueNode(nothing), ntuple(_ -> 0, Val(7)), DUMMY_NODE)

mutable struct ReentrantCLHLock <: CLHLock
    # TODO: node caching
    @atomic tail::LockQueueNode
    @const _pad::NTuple{7,Int}
    current::LockQueueNode
    @atomic owner::Union{Nothing,Task}
    count::Int
end

ReentrantCLHLock() =
    ReentrantCLHLock(LockQueueNode(nothing), ntuple(_ -> 0, Val(7)), DUMMY_NODE, nothing, 0)

isreentrant(::Lockable) = false
isreentrant(::ReentrantCLHLock) = true

function handle_reentrant_acquire(lock)
    isreentrant(lock) || return false
    if (@atomic :monotonic lock.owner) === current_task()
        lock.count += 1
        return true
    end
    return false
end

function start_reentrant_acquire(lock)
    isreentrant(lock) || return
    @atomic :monotonic lock.owner = current_task()
    lock.count = 1
    return
end

function handle_reentrant_release(lock)
    isreentrant(lock) || return false
    @assert (@atomic :monotonic lock.owner) === current_task()
    if (lock.count -= 1) > 0
        return true
    end
    @atomic :monotonic lock.owner = nothing
    return false
end

function ConcurrentUtils.try_race_acquire(lock::CLHLock)
    handle_reentrant_acquire(lock) && return Ok(nothing)
    pred = @atomic :monotonic lock.tail
    if !_islocked(pred)
        node = LockQueueNode(IsLocked())
        _, ok = @atomicreplace(:acquire_release, :acquire, lock.tail, pred => node)
        if ok
            start_reentrant_acquire(lock)
            lock.current = node
            return Ok(nothing)
        end
    end
    return Err(NotAcquirableError())
end

function ConcurrentUtils.acquire(lock::CLHLock; nspins = nothing)
    handle_reentrant_acquire(lock) && return

    node = LockQueueNode(IsLocked())
    # TODO: do we need acquire for `lock.tail`?
    pred = @atomicswap :acquire_release lock.tail = node
    if !_islocked(pred)
        atomic_fence(:acquire)
        # Main.@tlc notlocked
        @goto locked
    end
    for _ in oneto(nspins)
        if !_islocked(pred)
            atomic_fence(:acquire)
            # Main.@tlc spinlock
            @goto locked
        end
        spinloop()
    end

    task = current_task()
    # The acquire ordering is for `acquire(lock)` semantics. The release ordering is for
    # task's fields:
    state = @atomicswap :acquire_release pred.state = task
    if state isa IsLocked
        wait()
        @assert pred.state === nothing
        # @atomic :monotonic pred.state = nothing  # if reusing
    else
        @assert state === nothing
    end
    # Main.@tlc waited

    @label locked
    start_reentrant_acquire(lock)
    lock.current = node
    return
end

function ConcurrentUtils.release(lock::CLHLock)
    handle_reentrant_release(lock) && return
    node = lock.current
    # The release ordering is for `release(lock)` semantics. The acquire ordering is for
    # task's fields:
    state = @atomicswap :acquire_release node.state = nothing
    if state isa Task
        # The waiter is already sleeping. Wake it up.
        task = state::Task
        schedule(task)
    else
        @assert state isa IsLocked  # i.e., not `nothing`
    end
    return
end
