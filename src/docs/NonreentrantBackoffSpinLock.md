    NonreentrantBackoffSpinLock

A non-reentrant exponential backoff spin lock.

See also [`ReentrantBackoffSpinLock`](@ref) that provides a reentrant version.

# Extended help

`NonreentrantBackoffSpinLock` performs better than `Base.Threads.SpinLock` with high
contention.  [`NonreentrantCLHLock`](@ref) is better than `NonreentrantBackoffSpinLock` with
high contention with many worker threads (20 to 80; it depends on the machine).

Since `NonreentrantBackoffSpinLock` does not have a fallback "cooperative" waiting
mechanism, [`NonreentrantCLHLock`](@ref) is in general recommended.

## Memory ordering

`NonreentrantBackoffSpinLock` has the same semantics as [`ReentrantBackoffSpinLock`](@ref)
provided that each hand-off of the lock between tasks (if any) establishes a happened-before
edge.

## Supported operations

* `NonreentrantBackoffSpinLock(; [mindelay], [maxdelay]) -> lock`: Create a `lock`.
  `mindelay` (default: 1) specifies the number of [`spinloop`](@ref) called in the initial
  backoff.  `mindelay` (default: 1000) specifies the maximum backoff.
* [`acquire(lock::NonreentrantBackoffSpinLock; [mindelay], [maxdelay])`](@ref acquire)
  (`lock`): Acquire the `lock`.  Keyword arguments `mindelay` and `maxdelay` can be passed
  to override the values specified by the constructor.
* [`try_race_acquire(lock::NonreentrantBackoffSpinLock)`](@ref try_race_acquire)
  (`trylock`):
* [`release(lock::NonreentrantBackoffSpinLock)`](@ref) (`unlock`)
