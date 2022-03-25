    fetch_or!(thunk, promise::Promise{T}) -> value::T

Fetch an existing `value` or set `value = thunk()`.  The `thunk` is called at most once
for each instance of `promise`.

This is similar to [`try_fetch_or!`](@ref) but the caller cannot tell if `thunk` is called
or not by the return type.

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> p = Promise{Int}();

julia> fetch_or!(p) do
           println("called")
           123 + 456
       end
called
579

julia> fetch_or!(p) do
           println("called")
           42
       end
579
```
