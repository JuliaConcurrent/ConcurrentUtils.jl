###
### Base.AbstractLock adapters
###

ConcurrentUtils.acquire(lck::Base.AbstractLock) = lock(lck)
ConcurrentUtils.release(lck::Base.AbstractLock) = unlock(lck)

ConcurrentUtils.acquire(x) = Base.acquire(x)
ConcurrentUtils.release(x) = Base.release(x)

function ConcurrentUtils.try_acquire(lck::Base.AbstractLock)
    if trylock(lck)
        return Ok(nothing)
    else
        return Err(NotAcquirableError())
    end
end

function ConcurrentUtils.acquire_then(f, lock; acquire_options...)
    acquire(lock; acquire_options...)
    try
        return f()
    finally
        release(lock)
    end
end

###
### Main ConcurrentUtils' lock interface
###

abstract type Lockable end

Base.trylock(lck::Lockable) = Try.isok(try_acquire(lck))
Base.lock(lck::Lockable) = acquire(lck)
Base.unlock(lck::Lockable) = release(lck)

#=
function ConcurrentUtils.try_acquire_then(f, lock::Lockable)
    @? try_acquire(lock)
    try
        return f()
    finally
        release(lock)
    end
end
=#

###
### Reader-writer lock interface
###

abstract type ReadWriteLockable <: Lockable end

function ConcurrentUtils.acquire_read_then(f, lock::ReadWriteLockable)
    acquire_read(lock)
    try
        return f()
    finally
        release_read(lock)
    end
end

function ConcurrentUtils.acquire_write_then(f, lock::ReadWriteLockable)
    acquire_write(lock)
    try
        return f()
    finally
        release_write(lock)
    end
end

struct WriteLockHandle{RWLock} <: Lockable
    rwlock::RWLock
end

struct ReadLockHandle{RWLock} <: Lockable
    rwlock::RWLock
end

ConcurrentUtils.try_acquire(lock::WriteLockHandle) = try_acquire_write(lock.rwlock)
ConcurrentUtils.acquire(lock::WriteLockHandle) = acquire_write(lock.rwlock)
ConcurrentUtils.release(lock::WriteLockHandle) = release_write(lock.rwlock)

ConcurrentUtils.try_acquire(lock::ReadLockHandle) = try_acquire_read(lock.rwlock)
ConcurrentUtils.acquire(lock::ReadLockHandle) = acquire_read(lock.rwlock)
ConcurrentUtils.release(lock::ReadLockHandle) = release_read(lock.rwlock)

ConcurrentUtils.read_write_locks(lock::ReadWriteLockable = ReadWriteLock()) =
    (ReadLockHandle(lock), WriteLockHandle(lock))
