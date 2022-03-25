    spinloop()

A hint to the compiler, runtime, and hardware that `spinloop()` is in the middle of a spin
loop.  Call this in a spin loop that requires some other worker threads to make forward
progress in order for the current thread to make forward progress.

!!! warning
    Observe that the above sentence specifically mentions worker *threads* and not
    *`Task`s*.  A Julia programmer should always be alarmed whenever an API talks about
    threads instead of `Task`s.  Prefer higher-level APIs such as channels and condition
    variables.

    A proper use of `spinloop` requires extra cares such as a fallback that waits in the
    Julia scheduler and/or a mechanism that enables the spin loop code path given that other
    threads exist and a task that can break the spin loop is running or will be scheduled
    eventually.

# Implementation detail

It calls `GC.safepoint()` and `jl_cpu_pause`.
