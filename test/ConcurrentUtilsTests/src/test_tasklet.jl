module TestTasklet

using ConcurrentUtils
using Test

adder(x) = @tasklet Ref(x + 1)

function test_serial_tasklet()
    t = adder(2)
    @test try_race_fetch(t) == Err(NotSetError())
    @test t()[] == 3
    @test t() === t()
    @test try_race_fetch(t) == Ok(t())
end

get_a_dict() = @once Dict(:a => 1, :b => 2, :c => 3)

function test_get_a_dict()
    @test get_a_dict() === get_a_dict()
end

end  # module
