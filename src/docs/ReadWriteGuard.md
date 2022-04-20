    ReadWriteGuard(data)

Guard mutable `data`.  Use [`guarding`](@ref) and [`guarding_read`](@ref) to obtain
exclusive ("write") and shared ("read") access to `data`.

# Extended help

## Examples
```julia
julia> using ConcurrentUtils

julia> guard = ReadWriteGuard(Ref(0));

julia> guarding(guard) do ref
           ref[] += 1
       end
1

julia> guarding_read(guard) do ref
           ref[]  # must not mutate anything
       end
1
```
