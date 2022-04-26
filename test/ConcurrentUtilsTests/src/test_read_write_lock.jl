module TestReadWriteLock

using ConcurrentUtils
using Test

using ..Utils: poll_until, unfair_sleep

function test_no_blocks()
    lck = ReadWriteLock()

    @sync begin
        lock_read(lck)
        lock_read(lck)
        Threads.@spawn begin
            lock_read(lck)
            unlock_read(lck)
        end
        unlock_read(lck)
        unlock_read(lck)
    end

    lock(lck)
    unlock(lck)
end

function check_minimal_lock_interface(lck)
    phase = Threads.Atomic{Int}(0)
    lock(lck)
    @sync begin
        Threads.@spawn begin
            phase[] = 1
            lock(lck)
            unlock(lck)
            phase[] = 2
        end

        @test poll_until(() -> phase[] != 0)
        @test phase[] == 1
        sleep(0.01)
        @test phase[] == 1

        unlock(lck)
    end
    @test phase[] == 2
end

test_wlock() = check_minimal_lock_interface(ReadWriteLock())

function test_a_writer_blocks_a_reader()
    lck = ReadWriteLock()
    locked = Threads.Atomic{Bool}(false)
    @sync lock(lck) do
        Threads.@spawn begin
            lock_read(lck)
            locked[] = true
            unlock_read(lck)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function test_a_writer_blocks_a_writer()
    lck = ReadWriteLock()

    locked = Threads.Atomic{Bool}(false)
    @sync lock(lck) do
        Threads.@spawn begin
            lock(lck)
            locked[] = true
            unlock(lck)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function test_a_reader_blocks_a_writer()
    lck = ReadWriteLock()

    locked = Threads.Atomic{Bool}(false)
    @sync lock_read(lck) do
        Threads.@spawn begin
            lock(lck)
            locked[] = true
            unlock(lck)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function check_concurrent_mutex(nreaders, nwriters, ntries)
    lck = ReadWriteLock()

    limit = nwriters * ntries
    # nreads = Threads.Atomic{Int}(0)
    ref = Ref(0)
    @sync begin
        for _ in 1:nreaders
            Threads.@spawn while true
                lock_read(lck) do
                    # Threads.atomic_add!(nreads, 1)
                    ref[] < limit
                end || break
                yield()
            end
        end
        sleep(0.01)

        for _ in 1:nwriters
            Threads.@spawn for _ in 1:ntries
                lock(lck) do
                    local x = ref[]

                    # sleep about 3 μs
                    unfair_sleep(100)

                    ref[] = x + 1
                end
            end
        end
    end
    # @show nreads[]

    return ref[]
end

function test_concurrent_mutex()
    @testset for nwriters in [Threads.nthreads(), 64 * Threads.nthreads()]

        nwriters = 2
        ntries = 1000
        actual = check_concurrent_mutex(nwriters, nwriters, ntries)
        @test actual == nwriters * ntries
    end
end

end  # module
