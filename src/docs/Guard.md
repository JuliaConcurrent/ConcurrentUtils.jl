    Guard(data)

Guard mutable `data`.  Use [`guarding`](@ref) to obtain exclusive access to `data`.

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
