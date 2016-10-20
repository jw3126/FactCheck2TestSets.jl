import FactCheck2TestSets: linum, purge_linum, has_linum, migrate_string, tabs2spaces, unindent

s = "1 + 1 # foo"
@test migrate_string(s) == s

s = """@fact 1 --> 0 # this does not look right, does it?
    f(x) = 2
    @fact f(c) --> isfinite"""

t = "@test 1 == 0 # this does not look right, does it?\nf(x) = begin\n        2\n    end\n@test isfinite(f(c))"

@test migrate_string(s) == t

@testset "linum" begin
    l = "using Foo # none, line 3:"
    @test linum(l) |> get == 3
    @test purge_linum(l) == "using Foo"
    @test has_linum(l)

    l = "sqrt(sum(v .* v)) - 1"
    @test linum(l) |> isnull
    @test purge_linum(l) == l
    @test !has_linum(l)
end


@test tabs2spaces("    \tasd\tsad") == "        asd    sad"
@test unindent("        asd    sad") == "    asd    sad"
