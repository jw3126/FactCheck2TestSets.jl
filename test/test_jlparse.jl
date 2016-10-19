import FactCheck2TestSets: fact2testcore, fc2ts

@testset "@fact" begin
    @testset "rhs bool" begin
        ex = quote @fact the(truth) --> true end
        @test fact2testcore(ex) == :(the(truth))

        ex = quote @fact alie --> false end
        @test fact2testcore(ex) == :(!(alie))
    end

    @testset "rhs not" begin
        ex = quote @fact 1 --> not(2) end
        @test fact2testcore(ex) == :(!(1 == 2))

        ex = quote @fact foo --> not(isnan) end
        @test fact2testcore(ex) == :(!(isnan(foo)))
    end

    @testset "rhs roughly" begin
        ex = quote @fact 1 --> roughly(foo(bar)) end
        @test  fact2testcore(ex) == :(1 ≈ foo(bar))

        ex = quote @fact 1 --> roughly(2, 2) end
        @test fact2testcore(ex) == :(isapprox(1,2,atol=2))

        ex = quote @fact 1 --> roughly(2, rtol=3) end
        @test fact2testcore(ex) == :(isapprox(1,2,rtol=3))
    end

    @testset "rhs equals" begin
        ex = quote @fact a --> b(x) end
        @test fact2testcore(ex) == :(a == b(x))
    end

    @testset "rhs property" begin
        ex = quote @fact f(x, y, atol=3) --> isfinite end
        @test fact2testcore(ex) == :(isfinite(f(x,y,atol=3)))
    end

    @testset "rhs comparison" begin
        ex = quote @fact a --> less_than(b) end
        @test fact2testcore(ex) == :(a < b)
    end

end

@testset "@fact_throws" begin
    ex = :(@fact_throws DimensionMismatch x[3])
    @test fc2ts(ex) == :(@test_throws DimensionMismatch x[3])
    ex = :(@fact_throws x[3])
    @test fc2ts(ex) == :(@test_throws Exception x[3])
end
