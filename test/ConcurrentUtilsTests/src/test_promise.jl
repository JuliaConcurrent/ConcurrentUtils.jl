module TestPromise

using ConcurrentUtils
using Random: randperm
using Test

function test_serial()
    p = Promise()
    @test try_race_fetch(p) == Err(NotSetError())
    put!(p, 1)
    @test fetch(p) == 1
    @test wait(p) === nothing
    @test try_race_fetch(p) == Ok{Any}(1)
    @test try_race_put_with!(error, p) == Err{Any}(1)
    @test race_put_with!(error, p) == 1
    @test try_race_put!(p, 2) == Err{Any}(1)
    @test_throws OccupiedError{Any}(1) put!(p, 2)
end

function test_serial_try_race_fetch_or()
    p = Promise()
    @test try_race_put_with!(() -> 1, p) == Ok{Any}(1)
    @test try_race_put_with!(error, p) == Err{Any}(1)
    @test fetch(p) == 1
end

function test_serial_race_fetch_or()
    p = Promise()
    @test race_put_with!(() -> 1, p) == 1
    @test race_put_with!(error, p) == 1
    @test fetch(p) == 1
end

function test_serial_try_race_put()
    p = Promise()
    @test try_race_put!(p, 1) == Ok{Any}(1)
    @test try_race_put!(p, 2) == Err{Any}(1)
end

function check_concurrent_put_fetch(ntasks, ntries)
    promises = [[Promise{Int}() for _ in 1:ntasks] for _ in 1:ntries]
    shufflers = [randperm(ntasks) for _ in 1:ntries]
    outputs = [[Threads.Atomic{Int}(0) for _ in 1:ntasks] for _ in 1:ntries]
    @sync begin
        for itask in 1:ntasks
            Threads.@spawn for itry in 1:ntries
                put!(promises[itry][itask], itask)
                jtask = shufflers[itry][itask]
                x = fetch(promises[itry][jtask])
                Threads.atomic_add!(outputs[itry][jtask], x)
            end
        end
    end
    return [outputs[itry][itask][] for itask in 1:ntasks, itry in 1:ntries]
end

function test_concurrent_put_fetch(; ntries = 128)
    @testset for ntasks in [Threads.nthreads(), 64 * Threads.nthreads()]
        actual = check_concurrent_put_fetch(ntasks, ntries)
        desired = [itask for itask in 1:ntasks, _ in 1:ntries]
        @test actual == desired
    end
end

end  # module
