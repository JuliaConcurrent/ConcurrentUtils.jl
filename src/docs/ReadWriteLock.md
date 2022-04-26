    ReadWriteLock()

Create a read-write lock.

Use [`lock_read`](@ref) and [`unlock_read`](@ref) for taking reader (shared) lock.  Use
`lock` and `unlock` for taking writer (exclusive) lock.

See also: [`ReadWriteGuard`](@ref)

# Extended help
# Examples
```julia
julia> using ConcurrentUtils

julia> rwlock = ReadWriteLock();

julia> lock(rwlock) do
           # "mutate" data
       end;

julia> lock_read(rwlock) do
           # "read" data
       end;
```

## Supported operations

* [`lock_read`](@ref)
* [`trylock_read`](@ref) (not very efficient but lock-free)
* [`unlock_read`](@ref)
* `lock`
* `trylock`
* `unlock`
