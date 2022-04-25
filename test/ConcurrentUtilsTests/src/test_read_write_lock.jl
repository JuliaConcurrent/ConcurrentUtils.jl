module TestReadWriteLock

using ConcurrentUtils
using Test

using ..Utils: poll_until, unfair_sleep

function test_no_blocks()
    rlock, wlock = read_write_lock()

    @sync begin
        lock(rlock)
        lock(rlock)
        Threads.@spawn begin
            lock(rlock)
            unlock(rlock)
        end
        unlock(rlock)
        unlock(rlock)
    end

    lock(wlock)
    unlock(wlock)
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

function test_wlock()
    _, wlock = read_write_lock()
    check_minimal_lock_interface(wlock)
end

function test_a_writer_blocks_a_reader()
    rlock, wlock = read_write_lock()
    locked = Threads.Atomic{Bool}(false)
    @sync lock(wlock) do
        Threads.@spawn begin
            lock(rlock)
            locked[] = true
            unlock(rlock)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function test_a_writer_blocks_a_writer()
    _rlock, wlock = read_write_lock()

    locked = Threads.Atomic{Bool}(false)
    @sync lock(wlock) do
        Threads.@spawn begin
            lock(wlock)
            locked[] = true
            unlock(wlock)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function test_a_reader_blocks_a_writer()
    rlock, wlock = read_write_lock()

    locked = Threads.Atomic{Bool}(false)
    @sync lock(rlock) do
        Threads.@spawn begin
            lock(wlock)
            locked[] = true
            unlock(wlock)
        end

        sleep(0.01)
        @test !locked[]
    end
    @test locked[]
end

function check_concurrent_mutex(nreaders, nwriters, ntries)
    rlock, wlock = read_write_lock()

    limit = nwriters * ntries
    # nreads = Threads.Atomic{Int}(0)
    ref = Ref(0)
    @sync begin
        for _ in 1:nreaders
            Threads.@spawn while true
                lock(rlock) do
                    # Threads.atomic_add!(nreads, 1)
                    ref[] < limit
                end || break
                yield()
            end
        end
        sleep(0.01)

        for _ in 1:nwriters
            Threads.@spawn for _ in 1:ntries
                lock(wlock) do
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
