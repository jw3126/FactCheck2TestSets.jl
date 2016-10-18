unpack(x) = (@assert length(x)==1; x[1])
isjl(path) = splitext(path)[2] == ".jl"

function walkpaths(f, root)
    for (dir, _, files) in walkdir(root)
        for file in files
            path = joinpath(dir, file)
            f(path)
        end
    end
end

iscall(ex::Expr) = ex.head == :call
iscall(x) = false
calle(ex::Expr) = (@assert iscall(ex); ex.args[1])
callarg_unique(ex::Expr) = ex |> callargs |> unpack

function callargs(ex::Expr)
    @assert iscall(ex)
    ex.args[2:end]
end
