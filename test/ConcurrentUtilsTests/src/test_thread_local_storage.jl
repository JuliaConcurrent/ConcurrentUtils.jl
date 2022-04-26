module TestThreadLocalStorage

using ConcurrentUtils
using Test

function test_serial()
    tls = ThreadLocalStorage(Ref{Any})
    tls[][] = 123
    @test tls[][] == 123
end

function check_concurrent_increments!(tls, ntasks, ntries)
    outputs = zeros(Int, ntasks)
    @sync begin
        for itask in 1:ntasks
            Threads.@spawn begin
                tls[][] = 0
                for _ in 1:ntries
                    tls[][] += 1
                end
                outputs[itask] = tls[][]
            end
        end
    end
    return outputs
end

function test_concurrent_increments(; ntries = 128)
    @testset for ntasks in [Threads.nthreads(), 64 * Threads.nthreads()]
        tls = ThreadLocalStorage(Ref{Int})
        actual = check_concurrent_increments!(tls, ntasks, ntries)
        @test actual == fill(ntries, ntasks)

        storages = unsafe_takestorages!(tls)
        @test length(storages) == Threads.nthreads()  # in the current implementation
        @test all(ref isa Ref{Int} for ref in storages)

        @test isempty(tls.storages)
        tls[]
        @test !isempty(tls.storages)
        empty!(tls)
        @test isempty(tls.storages)
    end
end

end  # module
