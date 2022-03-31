module TestLocks

using ConcurrentUtils
using Test

using ..Utils: poll_until, unfair_sleep

function check_minimal_lock_interface(lock)
    phase = Threads.Atomic{Int}(0)
    acquire(lock)
    @sync begin
        Threads.@spawn begin
            phase[] = 1
            acquire(lock)
            release(lock)
            phase[] = 2
        end

        @test poll_until(() -> phase[] != 0)
        @test phase[] == 1
        sleep(0.01)
        @test phase[] == 1

        release(lock)
    end
    @test phase[] == 2
    # @test fetch(Threads.@spawn try_race_acquire(lock)) == Err(NotAcquirableError())
    # @test fetch(Threads.@spawn try_race_acquire(lock)) == Ok(nothing)
end

function test_minimal_lock_interface()
    @testset "$(nameof(T))" for T in [ReentrantLock, ReentrantCLHLock, NonreentrantCLHLock]
        check_minimal_lock_interface(T())
    end
end

function check_concurrent_mutex(lock, ntasks, ntries)
    ref = Ref(0)
    @sync for _ in 1:ntasks
        Threads.@spawn for _ in 1:ntries
            acquire_then(lock) do
                x = ref[]

                # sleep about 3 μs
                unfair_sleep(100)

                ref[] = x + 1
            end
        end
    end
    return ref[]
end

function test_concurrent_mutex()
    @testset "$(nameof(T))" for T in [
            ReentrantLock,
            ReentrantCLHLock,
            NonreentrantCLHLock,
            ReentrantBackoffSpinLock,
            NonreentrantBackoffSpinLock,
        ],
        ntasks in [Threads.nthreads(), 64 * Threads.nthreads()]

        ntries = 1000
        actual = check_concurrent_mutex(T(), ntasks, ntries)
        @test actual == ntasks * ntries
    end
end

function check_try_race_acquire(lock)
    acquire(lock)
    @test fetch(Threads.@spawn try_race_acquire(lock)) isa Err
    @test !fetch(Threads.@spawn race_acquire(lock))
    @test !fetch(Threads.@spawn trylock(lock))
    release(lock)
    @test try_race_acquire(lock) == Ok(nothing)
    release(lock)
    @test race_acquire(lock)
    release(lock)
    @test trylock(lock)
    release(lock)
end

function test_try_race_acquire()
    @testset "$(nameof(T))" for T in [
        ReentrantLock,
        ReentrantCLHLock,
        NonreentrantCLHLock,
        ReentrantBackoffSpinLock,
        NonreentrantBackoffSpinLock,
    ]
        check_try_race_acquire(T())
    end
end

function check_concurrent_try_race_acquire(tryacq, lock, ntasks, ntries)
    # TODO: accumulate Err results
    atomic = Threads.Atomic{Int}(0)
    ref = Ref(0)
    @sync for _ in 1:ntasks
        Threads.@spawn for _ in 1:ntries
            result = tryacq(lock)
            if Try.isok(result)
                ref[] += 1
                release(lock)
                Threads.atomic_add!(atomic, 1)
            end
        end
    end
    return ref[], atomic[]
end

function test_concurrent_try_race_acquire()
    @testset for ntasks in [Threads.nthreads(), 64 * Threads.nthreads()]
        ntries = 1000

        backofflocks = [ReentrantBackoffSpinLock, NonreentrantBackoffSpinLock]
        @testset "$(nameof(T))" for T in backofflocks
            @testset "no backoffs" begin
                actual, desired =
                    check_concurrent_try_race_acquire(T(), ntasks, ntries) do lock
                        # TODO: check that there's no `TooManyBackoffs` with `.nbackoffs > 0`
                        try_race_acquire(lock; ntries = 10)
                    end
                @test actual == desired
            end

            @testset "nbackoffs = 3" begin
                actual, desired =
                    check_concurrent_try_race_acquire(T(), ntasks, ntries) do lock
                        # TODO: check that there's no `TooManyBackoffs` with `.nbackoffs > 3`
                        try_race_acquire(lock; ntries = 10000, nbackoffs = 3)
                    end
                @test actual == desired
            end
        end
    end
end

end  # module
