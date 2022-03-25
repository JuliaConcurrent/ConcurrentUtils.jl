    TaskObliviousLock

A lock that can be released in a task that did not acquire the lock.  It does not support
reentrancy.

# Extended help
## Examples

```julia
julia> using ConcurrentUtils

julia> lock = TaskObliviousLock();

julia> acquire(lock);

julia> wait(Threads.@spawn release(lock));  # completes
```

## Supported operations

* [`acquire(lock::TaskObliviousLock)`](@ref acquire) (`lock`)
* [`release(lock::TaskObliviousLock)`](@ref) (`unlock`)

## Implementation detail

`TaskObliviousLock` is an alias to unspecified implementation of lock.  Currently, it is:

```julia
julia> TaskObliviousLock === NonreentrantCLHLock
true
```
