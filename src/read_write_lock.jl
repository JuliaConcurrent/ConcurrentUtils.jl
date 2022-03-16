const NOTLOCKED = UInt64(0)
const NREADERS_INC = UInt64(2)
const WRITELOCK_MASK = UInt64(1)

mutable struct ReadWriteLock <: ReadWriteLockable
    @atomic nreaders_and_writelock::UInt64
    # TODO: use condition variables with lock-free notify
    @const lock::ReentrantLock
    @const cond_read::Threads.Condition
    @const cond_write::Threads.Condition
end

function ReadWriteLock()
    lock = ReentrantLock()
    cond_read = Threads.Condition(lock)
    cond_write = Threads.Condition(lock)
    return ReadWriteLock(NOTLOCKED, lock, cond_read, cond_write)
end

# Not very efficient but lock-free
function ConcurrentUtils.try_acquire_read(rwlock::ReadWriteLock; ntries::Integer = 128)
    old = @atomic :monotonic rwlock.nreaders_and_writelock
    for _ in 1:ntries
        if iszero(old & WRITELOCK_MASK)
            # Try to acquire reader lock without the responsibility to receive or send the
            # notification:
            old, success = @atomicreplace(
                :acquire_release,
                :monotonic,
                rwlock.nreaders_and_writelock,
                old => old + NREADERS_INC,
            )
            success && return Ok(nothing)
        else
            return Err(AcquiredByWriterError())
        end
    end
    return Err(TooManyTries())
end

function ConcurrentUtils.acquire_read(rwlock::ReadWriteLock)
    n = @atomic :acquire_release rwlock.nreaders_and_writelock += NREADERS_INC
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

function ConcurrentUtils.release_read(rwlock::ReadWriteLock)
    n = @atomic :acquire_release rwlock.nreaders_and_writelock -= NREADERS_INC
    @assert iszero(n & WRITELOCK_MASK)
    if iszero(n)
        lock(rwlock.lock) do
            notify(rwlock.cond_write; all = false)
        end
    end
    return
end

function ConcurrentUtils.try_acquire_write(rwlock::ReadWriteLock)
    _, success = @atomicreplace(
        :acquire_release,
        :monotonic,
        rwlock.nreaders_and_writelock,
        NOTLOCKED => WRITELOCK_MASK,
    )
    if success
        return Ok(nothing)
    else
        return Err(NotAcquirableError())
    end
end

function ConcurrentUtils.acquire_write(rwlock::ReadWriteLock)
    if Try.isok(try_acquire_write(rwlock))
        return
    end
    lock(rwlock.lock) do
        while true
            if Try.isok(try_acquire_write(rwlock))
                return
            end
            wait(rwlock.cond_write)
        end
    end
end

function ConcurrentUtils.release_write(rwlock::ReadWriteLock)
    @assert !iszero(rwlock.nreaders_and_writelock & WRITELOCK_MASK)
    @atomic :acquire_release rwlock.nreaders_and_writelock &= ~WRITELOCK_MASK
    lock(rwlock.lock) do
        notify(rwlock.cond_read)
        notify(rwlock.cond_write; all = false)
    end
    return
end
