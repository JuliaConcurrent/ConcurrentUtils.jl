###
### Reader-writer lock interface
###

abstract type AbstractReadWriteLock <: Base.AbstractLock end

function ConcurrentUtils.acquire_read_then(f, lock::AbstractReadWriteLock)
    acquire_read(lock)
    try
        return f()
    finally
        release_read(lock)
    end
end

struct WriteLockHandle{RWLock} <: Base.AbstractLock
    rwlock::RWLock
end

struct ReadLockHandle{RWLock} <: Base.AbstractLock
    rwlock::RWLock
end

Base.trylock(lck::WriteLockHandle) = trylock(lck.rwlock)
Base.lock(lck::WriteLockHandle) = lock(lck.rwlock)
Base.unlock(lck::WriteLockHandle) = unlock(lck.rwlock)

Base.trylock(lck::ReadLockHandle) = Try.iok(try_race_acquire_read(lck.rwlock))
Base.lock(lck::ReadLockHandle) = acquire_read(lck.rwlock)
Base.unlock(lck::ReadLockHandle) = release_read(lck.rwlock)

ConcurrentUtils.read_write_lock(lock::AbstractReadWriteLock = ReadWriteLock()) =
    (ReadLockHandle(lock), WriteLockHandle(lock))
