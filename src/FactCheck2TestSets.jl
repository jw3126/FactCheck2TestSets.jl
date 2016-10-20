module FactCheck2TestSets
using MacroTools, ParserCombinator

# package code goes here
include("utils.jl")
include("jlparse.jl")
include("migration.jl")
include("parsercombinator.jl")
include("comments.jl")

end # module
