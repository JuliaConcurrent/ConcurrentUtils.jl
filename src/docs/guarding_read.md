    guarding_read(f, guard)

Apply `f` to the data wrapped in `guard` while obtaining shared access.

See: [`Guard`](@ref), [`ReadWriteGuard`](@ref), [`guarding`](@ref)

# Extended help
## Examples
```julia
julia> using ConcurrentUtils

julia> guard = ReadWriteGuard(Ref(0));

julia> guarding_read(guard) do ref
           ref[]  # must not mutate anything
       end
0
```
