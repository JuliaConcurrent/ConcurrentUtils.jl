module TestOnce

using ConcurrentUtils
using ConcurrentUtils.Internal: NOTSET
using Test

const O1 = Once{Vector{Int}}()
const O2 = Once{Vector{Int}}(() -> zeros(Int, 3))
const O3 = Once(() -> zeros(Int, 3))

function test_once_identity()
    @test O1[] === O1[]
    @test O2[] === O2[]
    @test O3[] === O3[]
end

const O1_NOUSE = Once{Vector{Int}}()
const O2_NOUSE = Once{Vector{Int}}(() -> zeros(Int, 3))
const O3_NOUSE = Once(() -> zeros(Int, 3))

function test_notset()
    @test O1_NOUSE.promise.value === NOTSET
    @test O2_NOUSE.promise.value === NOTSET
    @test O3_NOUSE.promise.value === NOTSET
end

end  # module
