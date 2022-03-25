    try_put!(promise::Promise{T}, value) -> Ok(value′::T) or Err(OccupiedError(existing::T))

Try to set a `value` in the `promise`.

Since the `value` is converted to `T` first, the returned `value′` may not be identical to
the input `value`.

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> p = Promise{Int}();

julia> try_put!(p, 123)
Try.Ok: 123

julia> try_put!(p, 456)
Try.Err: OccupiedError{Int64}(123)
```
