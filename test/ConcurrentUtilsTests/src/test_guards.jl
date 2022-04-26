module TestGuards

using ConcurrentUtils
using Test

function check_guarding(Guard; guarding = guarding)
    ch1 = Channel{Nothing}()
    ch2 = Channel{Nothing}()
    ref = Threads.Atomic{Int}(0)
    g = Guard(ref)
    @sync begin
        Threads.@spawn begin
            guarding(g) do ref
                ref[] = 111
                put!(ch1, nothing)
            end
        end
        Threads.@spawn begin
            put!(ch2, nothing)
            guarding(g) do ref
                ref[] = 222
            end
        end
        take!(ch1)
        sleep(0.01)
        @test ref[] == 111
        take!(ch2)
    end
    @test ref[] == 222
end

test_default_guard_guarding() = check_guarding(Guard)
test_default_guard_guarding_read() = check_guarding(Guard; guarding = guarding_read)
test_read_write_guard_guarding() = check_guarding(ReadWriteGuard)

function test_guarding_read()
    ch1 = Channel{Nothing}()
    ch2 = Channel{Nothing}()
    ch3 = Channel{Nothing}()
    ref = Threads.Atomic{Int}(0)
    g = ReadWriteGuard(ref)
    @sync begin
        Threads.@spawn begin
            guarding_read(g) do _ref
                put!(ch1, nothing)
                put!(ch1, nothing)
            end
        end
        Threads.@spawn begin
            guarding_read(g) do _ref
                put!(ch2, nothing)
                put!(ch2, nothing)
            end
        end
        Threads.@spawn begin
            put!(ch3, nothing)
            guarding(g) do ref
                ref[] = 111
            end
        end

        # Check that read access can be obtained multiple times (otherwise deadlock):
        take!(ch1)
        take!(ch2)

        # Make sure the writer is "about to" get the guard:
        take!(ch3)

        # The writer should not be able to get the lock:
        sleep(0.1)
        @test ref[] == 0

        # Finish the readers.  Now the writer should be able to proceed (otherwise
        # deadlock):
        take!(ch1)
        take!(ch2)
    end
    @test ref[] == 111
end

end  # module
