const Guard = GenericGuard{ReentrantLock}
const ReadWriteGuard = GenericReadWriteGuard{ReadWriteLock}

ConcurrentUtils.guardwith(data, lock) = GenericGuard(lock, data)
ConcurrentUtils.guardwith(data, lock::AbstractReadWriteLock) =
    GenericReadWriteGuard(lock, data)

function ConcurrentUtils.GenericGuard{Lock}(data) where {Lock}
    lock = Lock()
    return GenericGuard(lock, data)
end

function ConcurrentUtils.GenericReadWriteGuard{Lock}(data) where {Lock}
    lock = Lock()
    return GenericReadWriteGuard(lock, data)
end

function ConcurrentUtils.guarding(f!::F, g::GenericGuard) where {F}
    data = g.data
    criticalsection() = f!(data)
    lock(criticalsection, g.lock)
end

ConcurrentUtils.guarding_read(f::F, g::GenericGuard) where {F} =
    ConcurrentUtils.guarding(f, g)

function ConcurrentUtils.guarding(f!::F, g::GenericReadWriteGuard) where {F}
    data = g.data
    criticalsection() = f!(data)
    acquire_write_then(criticalsection, g.lock)
end

function ConcurrentUtils.guarding_read(f::F, g::GenericReadWriteGuard) where {F}
    data = g.data
    criticalsection() = f(data)
    acquire_read_then(criticalsection, g.lock)
end

# Maybe this is a bad idea since it's hard to remember that `guarding(_, ::ReadGuard)`
# should not mutate the data just from its syntax.
#=
struct ReadGuard{Guard}
    guard::Guard
end

struct WriteGuard{Guard}
    guard::Guard
end

ConcurrentUtils.guarding(f::F, readguard::ReadGuard) where {F} =
    ConcurrentUtils.guarding_read(f, readguard.guard)

ConcurrentUtils.guarding(f::F, writeguard::WriteGuard) where {F} =
    ConcurrentUtils.guarding(f, writeguard.guard)

function ConcurrentUtils.read_write_guard(guard::AbstractReadWriteGuard)
    readguard = ReadGuard(guard)
    writeguard = WriteGuard(guard)
    return (readguard, writeguard)
end

ConcurrentUtils.read_write_guard(lock::AbstractReadWriteLock, data) =
    ConcurrentUtils.read_write_guard(GenericReadWriteGuard(lock, data))
=#
