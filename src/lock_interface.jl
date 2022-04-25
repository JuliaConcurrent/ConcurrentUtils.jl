###
### Reader-writer lock interface
###

abstract type AbstractReadWriteLock <: Base.AbstractLock end

function ConcurrentUtils.lock_read(f, lock::AbstractReadWriteLock)
    lock_read(lock)
    try
        return f()
    finally
        unlock_read(lock)
    end
end

struct ReadLockHandle{RWLock} <: Base.AbstractLock
    rwlock::RWLock
end

Base.trylock(lck::ReadLockHandle) = trylock_read(lck.rwlock)
Base.lock(lck::ReadLockHandle) = lock_read(lck.rwlock)
Base.unlock(lck::ReadLockHandle) = unlock_read(lck.rwlock)

ConcurrentUtils.read_write_lock(lock::AbstractReadWriteLock = ReadWriteLock()) =
    (ReadLockHandle(lock), lock)
