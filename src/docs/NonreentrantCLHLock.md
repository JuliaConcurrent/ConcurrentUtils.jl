    NonreentrantCLHLock

A (non-reentrant) CLH "spinnable" lock that provides first-come-first-served fairness.
Keyword argument `nspins::Integer` can be passed to [`acquire`](@ref) to specify a number of
spins tried before falling back to "cooperative" waiting in the Julia scheduler.

# Extended help

`NonreentrantCLHLock` implements the spin lock by Craig (1993) and Magnussen, Landin, and
Hagersten (1994) with a fallback to "cooperatively" wait in the scheduler instead of
spinning (hence "spinnable").  See [`ReentrantCLHLock`](@ref) that provides a reentrant
version.

## Supported operations

* [`acquire(lock::NonreentrantCLHLock; [nspins::Integer])`](@ref acquire) (`lock`)
* [`try_race_acquire(lock::NonreentrantCLHLock)`](@ref try_race_acquire) (`trylock`): Not very
  efficient but lock-free.  Fail with `AcquiredByWriterError`.
* [`release(lock::NonreentrantCLHLock)`](@ref) (`unlock`)
