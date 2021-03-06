export convert_pkg, convert_file, convert_folder

using ParserCombinator

const ws = P"\s*"
const ws1 = P"\s\s*"
const indent = p"\s*" > string
const body = p".*" > string
const braces = p"\(.*\)" > (x -> string(x[2:end-1]))
const chars = p"[a-zA-Z][a-zA-Z]*" > string
const nocomment = p"[^#]*"


#### context
type Context
    name
end
context_name = (P"context|facts") + braces
context_header = context_name + ws + E"do" > Context
writecore(c::Context) = string("@testset", " ", c.name, " begin")

type Fact code end

Fact(args...) = Fact(string(args...))
FactThrows(args...) = FactThrows(string(args...))

fact_throws = p"[^#]*@fact_throws" + nocomment > Fact
fact = p"[^#]*@fact" + nocomment > Fact
facts = fact_throws | fact

function writecore(f::Fact)
    ex = f.code |> parse |> MacroTools.striplines
    isincomplete(ex) && return "$(f.code) # TODO FactCheck2TestSets Parsing Error"
    ex |> fc2ts |> string |> sugar
end

type Line
    indent
    core
    comment
end

comment = (p"#.*" | ws) > string
core = context_header | facts
line = indent + core + ws + comment > Line

writecomment(s) = s == "" ? "" : string(" ", s)
function writeline(l::Line)
    string(l.indent, writecore(l.core), writecomment(l.comment))
end

type Blob code end
blob = p".*" > Blob
writeline(b::Blob) = b.code

#### ignore
immutable BitBucket end

ignore_exitstatus = ws + (E"FactCheck.exitstatus()"|ws) + ws + Eos() > BitBucket
ignore_usingtest = ws + (E"using Base.Test") + ws + Eos() > BitBucket
ignore = ignore_usingtest | ignore_exitstatus

writeline(::BitBucket) = ""

immutable UsingFactCheck end
usingfactcheck = ws + E"using FactCheck" + ws + Eos() > UsingFactCheck
writeline(::UsingFactCheck) = "using Base.Test"
anyline = usingfactcheck | ignore | line | blob

function convert_line(s::String)
    #isinteresting(s) || return s
    parse_one(s, anyline) |> unpack |> writeline
end
