abstract type AbstractReadWriteLock <: Base.AbstractLock end

const NOTLOCKED = UInt64(0)
const NREADERS_INC = UInt64(2)
const WRITELOCK_MASK = UInt64(1)

const NReadersAndWritelock = UInt64

mutable struct ReadWriteLock <: AbstractReadWriteLock
    @atomic nreaders_and_writelock::NReadersAndWritelock
    # TODO: use condition variables with lock-free notify
    @const lock::ReentrantLock
    @const cond_read::Threads.Condition
    @const cond_write::Threads.Condition
end

const OFFSET_NREADERS_AND_WRITELOCK =
    fieldoffset_by_name(ReadWriteLock, :nreaders_and_writelock)

function ReadWriteLock()
    lock = ReentrantLock()
    cond_read = Threads.Condition(lock)
    cond_write = Threads.Condition(lock)
    return ReadWriteLock(NOTLOCKED, lock, cond_read, cond_write)
end

# Not very efficient but lock-free
function ConcurrentUtils.trylock_read(rwlock::ReadWriteLock; nspins = -∞, ntries = -∞)
    local ns::Int = 0
    local nt::Int = 0
    while true
        old = @atomic :monotonic rwlock.nreaders_and_writelock
        if iszero(old & WRITELOCK_MASK)
            # Try to acquire reader lock without the responsibility to receive or send the
            # notification:
            old, success = @atomicreplace(
                :acquire_release,
                :monotonic,
                rwlock.nreaders_and_writelock,
                old => old + NREADERS_INC,
            )
            success && return true
            nt += 1
            nt < ntries || return false
        end
        ns += 1
        ns < nspins || return false
    end
end

function ConcurrentUtils.lock_read(rwlock::ReadWriteLock)

    # Using hardware FAA
    ptr = Ptr{NReadersAndWritelock}(
        pointer_from_objref(rwlock) + OFFSET_NREADERS_AND_WRITELOCK,
    )
    GC.@preserve rwlock begin
        _, n = UnsafeAtomics.modify!(ptr, +, NREADERS_INC, acq_rel)
    end
    # n = @atomic :acquire_release rwlock.nreaders_and_writelock += NREADERS_INC

    if iszero(n & WRITELOCK_MASK)
        return
    end
    lock(rwlock.lock) do
        while true
            local n = @atomic :acquire rwlock.nreaders_and_writelock
            if iszero(n & WRITELOCK_MASK)
                @assert n > 0
                return
            end
            wait(rwlock.cond_read)
        end
    end
end

function ConcurrentUtils.unlock_read(rwlock::ReadWriteLock)

    # Using hardware FAA
    ptr = Ptr{NReadersAndWritelock}(
        pointer_from_objref(rwlock) + OFFSET_NREADERS_AND_WRITELOCK,
    )
    GC.@preserve rwlock begin
        _, n = UnsafeAtomics.modify!(ptr, -, NREADERS_INC, acq_rel)
    end
    # n = @atomic :acquire_release rwlock.nreaders_and_writelock -= NREADERS_INC

    @assert iszero(n & WRITELOCK_MASK)
    if iszero(n)
        lock(rwlock.lock) do
            notify(rwlock.cond_write; all = false)
        end
    end
    return
end

function Base.trylock(rwlock::ReadWriteLock)
    _, success = @atomicreplace(
        :acquire_release,
        :monotonic,
        rwlock.nreaders_and_writelock,
        NOTLOCKED => WRITELOCK_MASK,
    )
    return success::Bool
end

function Base.lock(rwlock::ReadWriteLock)
    if trylock(rwlock)
        return
    end
    lock(rwlock.lock) do
        while true
            if trylock(rwlock)
                return
            end
            wait(rwlock.cond_write)
        end
    end
end

function Base.unlock(rwlock::ReadWriteLock)
    @assert !iszero(rwlock.nreaders_and_writelock & WRITELOCK_MASK)
    @atomic :acquire_release rwlock.nreaders_and_writelock &= ~WRITELOCK_MASK
    lock(rwlock.lock) do
        notify(rwlock.cond_read)
        notify(rwlock.cond_write; all = false)
    end
    return
end

###
### High-level APIs
###

ConcurrentUtils.lock_read(lck) = lock(lck)
ConcurrentUtils.unlock_read(lck) = unlock(lck)

function ConcurrentUtils.lock_read(f, lock)
    lock_read(lock)
    try
        return f()
    finally
        unlock_read(lock)
    end
end
