    acquire_then(f, lock; acquire_options...) -> y

Execute a thunk `f` in a critical section protected by `lock` and return the value `y`
returned from `f`.  Keyword arguments are passed to [`acquire`](@ref).

# Extended help

## Examples

```julia
julia> using ConcurrentUtils

julia> lock = ReentrantCLHLock();

julia> acquire_then(lock; nspins = 10) do
           123 + 456
       end
579
```
