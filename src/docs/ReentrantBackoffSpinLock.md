    ReentrantBackoffSpinLock

A reentrant exponential backoff spin lock.

See also [`NonreentrantBackoffSpinLock`](@ref) that provides a non-reentrant version.

# Extended help

## Memory ordering

A `release` invocation on a `lock` establishes happened-before edges to subsequent
invocations of `acquire` and `try_race_acquire` that returns an `Ok` on the same `lock`.

## Supported operations

* `ReentrantBackoffSpinLock(; [mindelay], [maxdelay]) -> lock`: Create a `lock`.
  `mindelay` (default: 1) specifies the number of [`spinloop`](@ref) called in the initial
  backoff.  `mindelay` (default: 1000) specifies the maximum backoff.
* [`acquire(lock::ReentrantBackoffSpinLock; [mindelay], [maxdelay])`](@ref acquire)
  (`lock`): Acquire the `lock`.  Keyword arguments `mindelay` and `maxdelay` can be passed
  to override the values specified by the constructor.
* [`try_race_acquire(lock::ReentrantBackoffSpinLock)`](@ref try_race_acquire)
  (`trylock`):
* [`release(lock::ReentrantBackoffSpinLock)`](@ref) (`unlock`)
