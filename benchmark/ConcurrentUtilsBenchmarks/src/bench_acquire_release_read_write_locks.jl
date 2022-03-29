module BenchAcquireReleaseReadWriteLocks

using BenchmarkTools
using ConcurrentUtils
using SyncBarriers

include("raynal_read_write_lock.jl")

raynal_read_write_lock() = read_write_lock(RaynalReadWriteLock())

function single_reentrantlock()
    lock = ReentrantLock()
    return (lock, lock)
end

function setup_repeat_acquire_release(
    rlock,
    wlock;
    ntries = 2^2,
    nrlocks = 2^8,
    ntasks = Threads.nthreads(),
    nspins_barrier = nothing,
)
    init = CentralizedBarrier(ntasks + 1)
    barrier = CentralizedBarrier(ntasks)
    workers = map(1:ntasks) do i
        Threads.@spawn begin
            acquire(rlock)
            release(rlock)
            cycle!(init[i])
            cycle!(init[i])
            for _ in 1:ntries
                acquire(wlock)
                release(wlock)
                for _ in 1:nrlocks
                    acquire(rlock)
                    release(rlock)
                end
                cycle!(barrier[i], nspins_barrier)
            end
        end
    end
    cycle!(init[ntasks+1])

    return function benchmark()
        cycle!(init[ntasks+1])
        foreach(wait, workers)
    end
end

default_ntasks_list() = [
    Threads.nthreads(),
    # 8 * Threads.nthreads(),
    # 64 * Threads.nthreads(),
]

function setup(;
    smoke = false,
    ntries = smoke ? 10 : 2^2,
    nrlocks = smoke ? 3 : 2^8,
    ntasks_list = default_ntasks_list(),
    nspins_barrier = 1_000_000,
    locks = [read_write_lock, raynal_read_write_lock, single_reentrantlock],
)
    suite = BenchmarkGroup()
    for ntasks in ntasks_list
        actual_nspins_barrier = ntasks > Threads.nthreads() ? nothing : nspins_barrier
        s1 = suite["ntasks=$ntasks"] = BenchmarkGroup()
        for factory in locks
            s1["impl=:$(nameof(factory))"] = @benchmarkable(
                benchmark(),
                setup = begin
                    benchmark = setup_repeat_acquire_release(
                        $factory()...;
                        ntries = $ntries,
                        nrlocks = $nrlocks,
                        ntasks = $ntasks,
                        nspins_barrier = $actual_nspins_barrier,
                    )
                end,
                evals = 1,
            )
        end
    end
    return suite
end

function clear() end

end  # module
