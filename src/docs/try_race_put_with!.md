    try_race_put_with!(thunk, promise::Promise{T}) -> Ok(computed::T) or Err(existing::T)

Fetch an `existing` value or set a `computed` value (`computed = thunk()`).  The `thunk` is
called at most once for each instance of `promise`.

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> p = Promise{Int}();

julia> try_race_put_with!(p) do
           123 + 456
       end
Try.Ok: 579

julia> try_race_put_with!(p) do
           42
       end
Try.Err: 579
```
