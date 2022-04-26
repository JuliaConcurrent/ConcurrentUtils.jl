    trylock_read(rwlock) -> acquired::Bool

Try to take reader lock. Return `true` on success.

This function is lock-free but may not be efficient.

See also: [`ReadWriteLock`](@ref)
