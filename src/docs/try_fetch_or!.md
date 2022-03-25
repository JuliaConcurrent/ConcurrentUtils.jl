    try_fetch_or!(thunk, promise::Promise{T}) -> Ok(existing::T) or Err(computed::T)

Fetch an `existing` value or set a `computed` value (`computed = thunk()`).  The `thunk` is
called at most once for each instance of `promise`.

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> p = Promise{Int}();

julia> try_fetch_or!(p) do
           123 + 456
       end
Try.Err: 579

julia> try_fetch_or!(p) do
           42
       end
Try.Ok: 579
```
