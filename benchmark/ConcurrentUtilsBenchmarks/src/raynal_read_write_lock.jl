using ConcurrentUtils
using ConcurrentUtils.Internal: AbstractReadWriteLock  # TODO: export?

# https://en.wikipedia.org/wiki/Readers%E2%80%93writer_lock#Using_two_mutexes
mutable struct RaynalReadWriteLock{ReadLock,GlobalLock} <: AbstractReadWriteLock
    readlock::ReadLock
    globallock::GlobalLock  # must be task-oblivious
    _pad::NTuple{7,Int}
    nreaders::Int
end

RaynalReadWriteLock(readlock = ReentrantLock(), globallock = TaskObliviousLock()) =
    RaynalReadWriteLock(readlock, globallock, ntuple(_ -> 0, Val(7)), 0)

function ConcurrentUtils.acquire_read(lock::RaynalReadWriteLock)
    acquire_then(lock.readlock) do
        n = lock.nreaders
        lock.nreaders = n + 1
        if n == 0
            acquire(lock.globallock)
        end
    end
end

function ConcurrentUtils.release_read(lock::RaynalReadWriteLock)
    acquire_then(lock.readlock) do
        n = lock.nreaders -= 1
        if n == 0
            release(lock.globallock)
        end
    end
end

ConcurrentUtils.acquire_write(lock::RaynalReadWriteLock) = acquire(lock.globallock)
ConcurrentUtils.release_write(lock::RaynalReadWriteLock) = release(lock.globallock)
