    guarding(f!, guard)

Apply `f!` to the data wrapped in `guard` while obtaining exclusive access.

See: [`Guard`](@ref), [`ReadWriteGuard`](@ref), [`guarding_read`](@ref)

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> guard = Guard(Ref(0));

julia> guarding(guard) do ref
           ref[] += 1
       end
1
```
