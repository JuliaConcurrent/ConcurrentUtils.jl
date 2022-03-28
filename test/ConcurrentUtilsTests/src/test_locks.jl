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
    @test fetch(Threads.@spawn try_race_acquire(lock)) == Err(NotAcquirableError())
    release(lock)
    @test try_race_acquire(lock) == Ok(nothing)
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

end  # module
