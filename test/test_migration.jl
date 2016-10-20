import FactCheck2TestSets: migrate_REQUIRE_string, migrate_string

@testset "REQUIRE" begin
    datapath = joinpath(splitdir(@__FILE__)[1], "data")

    path = joinpath(datapath, "REQUIRE1")
    @test migrate_REQUIRE_string(path) == "Foo\nBar\nBaseTestNext\n"
    path = joinpath(datapath, "REQUIRE2")
    @test migrate_REQUIRE_string(path) == "Foo\nBar\nBaseTestNext\n"
    path = joinpath(datapath, "REQUIRE3")
    @test migrate_REQUIRE_string(path) == "Images\nGeometryTypes\nBaseTestNext\n"
    path = "doesnotexist"
    @test migrate_REQUIRE_string(path) == "BaseTestNext\n"
end
