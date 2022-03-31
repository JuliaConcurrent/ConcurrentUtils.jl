mutable struct ThreadLocalStorage{T,Factory}
    @const factory::Factory
    @atomic storages::Vector{T}
    @const cond::Threads.Condition
end

ThreadLocalStorage{T}(factory) where {T} =
    ThreadLocalStorage{T,_typeof(factory)}(factory, T[], Threads.Condition())

function ThreadLocalStorage(factory)
    value = factory()
    return ThreadLocalStorage{typeof(value),_typeof(factory)}(
        factory,
        [value],
        Threads.Condition(),
    )
end

function ConcurrentUtils.unsafe_takestorages!(tls::ThreadLocalStorage{T}) where {T}
    storages = @atomic :monotonic tls.storages
    @atomic :monotonic tls.storages = T[]
    return storages
end

function Base.empty!(tls::ThreadLocalStorage{T}) where {T}
    @atomic :release tls.storages = T[]
    return tls
end

function getstorages!(tls::ThreadLocalStorage{T}) where {T}
    storages = @atomic :acquire tls.storages
    if length(storages) >= Threads.nthreads()
        return storages
    end
    lock(tls.cond) do
        local storages = @atomic :acquire tls.storages
        n = length(storages)
        if n >= Threads.nthreads()
            return storages
        end
        newstorages = similar(storages, Threads.nthreads())
        copyto!(newstorages, storages)
        local factory = tls.factory
        for i in n+1:Threads.nthreads()
            local value = factory()::T
            newstorages[i] = value
        end
        @atomic :release tls.storages = newstorages
        return newstorages
    end
end

Base.getindex(tls::ThreadLocalStorage) = getstorages!(tls)[Threads.threadid()]


const THREAD_LOCAL_RNG = ThreadLocalStorage(Xoshiro)
