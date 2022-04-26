struct NotSet end

mutable struct Promise{T}
    @atomic value::Union{T,NotSet}
    @const cond::Threads.Condition
end

Promise{T}() where {T} = Promise{T}(NotSet(), Threads.Condition())
Promise() = Promise{Any}()

function Base.fetch(promise::Promise)
    value = @atomic :monotonic promise.value
    if !(value isa NotSet)
        atomic_fence(:acquire)
        return value
    end
    lock(promise.cond) do
        local value = @atomic :monotonic promise.value
        value isa NotSet || return value
        wait(promise.cond)
        value = @atomic :monotonic promise.value
        value isa NotSet && error("unreachable: invalid notify")
        return value
    end
end

function Base.wait(promise::Promise)
    fetch(promise)
    return
end

function ConcurrentUtils.try_race_fetch(promise::Promise{T}) where {T}
    value = @atomic :monotonic promise.value
    if value isa NotSet
        return Err(NotSetError())
    else
        atomic_fence(:acquire)
        return Ok{T}(value)
    end
end

ConcurrentUtils.race_put_with!(f::F, promise::Promise) where {F} =
    Try.unwrap_or_else(identity, try_race_put_with!(f, promise))

ConcurrentUtils.race_put!(promise::Promise, value) =
    Try.unwrap_or_else(identity, try_race_put!(promise, value))

function ConcurrentUtils.try_race_put_with!(
    thunk::F,
    promise::Promise{T},
)::Union{Ok{T},Err{T}} where {F,T}
    old = @atomic :monotonic promise.value
    if !(old isa NotSet)
        atomic_fence(:acquire)
        return Err{T}(old)
    end
    lock(promise.cond) do
        local old = @atomic :monotonic promise.value
        if !(old isa NotSet)
            return Err{T}(old)
        end
        new = thunk()
        new = convert(eltype(promise), new)
        @atomic :release promise.value = new
        notify(promise.cond)
        return Ok{T}(new)
    end
end

ConcurrentUtils.try_race_put!(promise, value) =
    ConcurrentUtils.try_race_put_with!(Returns(value), promise)

function Base.put!(promise::Promise{T}, value) where {T}
    Try.unwrap_or_else(try_race_put!(promise, value)) do existing
        throw(OccupiedError{T}(existing))
    end
end
