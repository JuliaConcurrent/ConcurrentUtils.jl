struct Once{T,F}
    factory::F
    promise::Promise{T}
end

function Once{T}() where {T}
    T isa Type || _once_invalid_type_parameter(T)
    return Once{T,Type{T}}(T, Promise{T}())
end

function Once{T}(f) where {T}
    T isa Type || _once_invalid_type_parameter(T)
    return Once{T,_typeof(f)}(f, Promise{T}())
end

@noinline _once_invalid_type_parameter(@nospecialize T) =
    error("`Once{T}`` expcet a type for `T`; got T = $T")

function Once(f)
    value = f()
    T = typeof(value)
    promise = Promise{T}()
    # Not using the `value` calculated above in `Promise{T}` to avoid serializing into the
    # precompiled module just in case it is used as in `const O = Once(f)` in a package.
    return Once{T,_typeof(f)}(f, promise)
end

Base.getindex(once::Once) = race_put_with!(once.factory, once.promise)

function Base.delete!(once::Once)
    @atomic :monotonic once.promise.value = NOTSET
    return once
end
