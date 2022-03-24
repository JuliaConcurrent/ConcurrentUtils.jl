module BenchAcquireReleaseCoOpLocks

using ..BenchAcquireReleaseSpinLocks

setup(; options...) = BenchAcquireReleaseSpinLocks.setup(;
    nspins_list = [0],
    ntasks_list = [16 * Threads.nthreads()],
    ntries = 2,
    options...,
)

function clear() end

end  # module
