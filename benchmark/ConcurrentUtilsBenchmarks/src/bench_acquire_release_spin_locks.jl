module BenchAcquireReleaseSpinLocks

using BenchmarkTools
using ConcurrentUtils
using SyncBarriers

supports_nspins(
    ::Type{T},
) where {T<:Union{Base.AbstractLock,ConcurrentUtils.Internal.Lockable}} =
    T <: Union{ReentrantCLHLock,NonreentrantCLHLock}

supports_nspins(::Type) = error("unsupported")
supports_nspins(lock) = supports_nspins(typeof(lock))

function setup_repeat_acquire_release(
    lock;
    ntries = 2^10,
    ntasks = Threads.nthreads(),
    nspins = 1_000_000,
    nspins_barrier = nspins,
)
    init = CentralizedBarrier(ntasks + 1)
    barrier = CentralizedBarrier(ntasks)
    workers = map(1:ntasks) do i
        Threads.@spawn begin
            acquire(lock)
            release(lock)
            cycle!(init[i])
            cycle!(init[i])
            local n = 0
            while true
                if supports_nspins(lock)
                    acquire(lock; nspins = nspins)
                else
                    acquire(lock)
                end
                release(lock)
                (n += 1) < ntries || break
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
    ntries = smoke ? 10 : 2^10,
    ntasks_list = default_ntasks_list(),
    nspins_list = [100, 1_000, 10_000],
    locks = [
        ReentrantLock,
        Threads.SpinLock,
        ReentrantCLHLock,
        NonreentrantCLHLock,
        ReentrantBackoffSpinLock,
        NonreentrantBackoffSpinLock,
    ],
)
    suite = BenchmarkGroup()
    for T in locks
        s1 = suite["impl=:$(nameof(T))"] = BenchmarkGroup()
        for nspins in (supports_nspins(T) ? nspins_list : [0])
            s2 = s1["nspins=$nspins"] = BenchmarkGroup()
            for ntasks in ntasks_list
                nspins_barrier = ntasks > Threads.nthreads() ? nothing : 1_000_000
                s2["ntasks=$ntasks"] = @benchmarkable(
                    benchmark(),
                    setup = begin
                        benchmark = setup_repeat_acquire_release(
                            $T();
                            ntries = $ntries,
                            ntasks = $ntasks,
                            nspins = $(nspins == 0 ? nothing : nspins),
                            nspins_barrier = $nspins_barrier,
                        )
                    end,
                    evals = 1,
                )
            end
        end
    end
    return suite
end

function clear() end

end  # module
