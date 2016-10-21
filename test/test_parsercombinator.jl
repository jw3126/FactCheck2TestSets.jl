import FactCheck2TestSets: convert_line

@testset "convert_line" begin
    @test convert_line("asdf") == "asdf"

    s = """context("foo") do """
    @test convert_line(s) == "@testset \"foo\" begin"

    s = """facts("GeometryTypes") do"""
    @test convert_line(s) == "@testset \"GeometryTypes\" begin"

    s = """@fact_throws ndims(HyperCube)"""
    @test convert_line(s) == "@test_throws Exception ndims(HyperCube)"

    s = """@fact min_euclidean(c1,c2) --> roughly(5)"""
    @test convert_line(s) == "@test min_euclidean(c1,c2) ≈ 5"


    s = " @fact Inf --> not(isfinite)"
    @test convert_line(s) == " @test !(isfinite(Inf))"

    s = "  @fact make_checked_nan(S) --> true"
    @test convert_line(s) == "  @test make_checked_nan(S)"

    s = "@fact_throws ErrorException colorim(rand(UInt8, 3, 5, 3))"
    @test convert_line(s) == "@test_throws ErrorException colorim(rand(UInt8,3,5,3))"

    s = "@fact Images.ssd(imgs, (A.-mnA)/(mxA-mnA)) --> less_than(eps(UFixed16))"
    @test convert_line(s) == "@test Images.ssd(imgs,(A .- mnA) / (mxA - mnA)) < eps(UFixed16)"

    s = "for id in ids @fact corners[id] --> true end"
    @test convert_line(s) == "for id = ids\n    @test corners[id]\nend"


    s = "FactCheck.exitstatus()"
    @test convert_line(s) == ""

    s = """using FactCheck"""
    @test convert_line(s) == "if VERSION >= v\"0.5.0-dev+7720\"\n    using Base.Test\nelse\n    using BaseTestNext\n    const Test = BaseTestNext\nend"

    # s = "@fact abs(ovr[1, 2] - RGB{Float32}(a[1, 2], b[1, 2], a[1, 2])) --> roughly(0, atol=1e-5)"
    s = """@fact dimindex(imgds, "z") --> 0"""
    @test convert_line(s) == "@test dimindex(imgds,\"z\") == 0"

    s = """@fact update(l, 1, 1)   --> (leaf) -> hasindex(leaf[1], 1)"""
    @test convert_line(s) == "@test ((leaf->begin \n            hasindex(leaf[1],1)\n        end))(update(l,1,1))"

    s = "@fact PersistentVector([1])   --> not(isempty)"
    @test convert_line(s) == "@test !(isempty(PersistentVector([1])))"

    s = """    @fact_throws FileIO.WriterError save(Stream(format"BROKEN", STDOUT))"""
    @test convert_line(s) == "    @test_throws FileIO.WriterError save(Stream(format\"BROKEN\",STDOUT))"

end
