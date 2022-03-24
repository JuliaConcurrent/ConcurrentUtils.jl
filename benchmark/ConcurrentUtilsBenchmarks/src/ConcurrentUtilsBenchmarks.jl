module ConcurrentUtilsBenchmarks

using BenchmarkTools: Benchmark, BenchmarkGroup

include("bench_acquire_release_spin_locks.jl")
include("bench_acquire_release_coop_locks.jl")
include("bench_acquire_release_read_write_locks.jl")
include("bench_acquire_release_read_locks.jl")

const MODULES = [
    BenchAcquireReleaseSpinLocks,
    BenchAcquireReleaseCoOpLocks,
    BenchAcquireReleaseReadWriteLocks,
    BenchAcquireReleaseReadLocks,
    # ...
]

function setup(; options...)
    suite = BenchmarkGroup()
    for m in MODULES
        str = string(nameof(m))
        @assert startswith(str, "Bench")
        name = str[length("Bench"):end]
        suite[name] = m.setup(; options...)
    end
    return suite
end

function set_smoke_params!(bench)
    bench.params.seconds = 0.001
    bench.params.evals = 1
    bench.params.samples = 1
    bench.params.gctrial = false
    bench.params.gcsample = false
    return bench
end

foreach_benchmark(f!, bench::Benchmark) = f!(bench)
function foreach_benchmark(f!, group::BenchmarkGroup)
    for x in values(group)
        foreach_benchmark(f!, x)
    end
end

function setup_smoke()
    suite = setup(; smoke = true)
    foreach_benchmark(set_smoke_params!, suite)
    return suite
end

function clear()
    for m in MODULES
        m.clear()
    end
end

end  # module ConcurrentUtilsBenchmarks
