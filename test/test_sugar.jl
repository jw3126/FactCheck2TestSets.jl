import FactCheck2TestSets: sugar_stringmacros

@testset "sugar_stringmacros" begin
    s = """    @test typeof(q) == File{@format_str("PLY_BINARY")}"""
    @test sugar_stringmacros(s) == "    @test typeof(q) == File{format\"PLY_BINARY\"}"
    s = """        @test read(s,2) == @b_str("UM")"""
    @test sugar_stringmacros(s) == "        @test read(s,2) == b\"UM\""
    s = """@test_throws FileIO.LoaderError load(Stream(@format_str("BROKEN"),STDIN))"""
    @test sugar_stringmacros(s) == "@test_throws FileIO.LoaderError load(Stream(format\"BROKEN\",STDIN))"
    s = randstring(10)
    @test sugar_stringmacros(s) == s
end
