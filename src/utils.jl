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

ismacrocall(x) = false
ismacrocall(ex::Expr) = ex.head == :macrocall

iscall(ex::Expr) = ex.head == :call
iscall(x) = false

iscall_fun_or_macro(x) = iscall(x) | ismacrocall(x)

calle(ex::Expr) = (@assert iscall_fun_or_macro(ex); ex.args[1])
callarg_unique(ex::Expr) = ex |> callargs |> unpack

function callargs(ex::Expr)
    @assert iscall_fun_or_macro(ex)
    ex.args[2:end]
end

const INCOMPLETE = parse("[")
isincomplete(ex) = ex == INCOMPLETE

immutable MacroCall{f} end
immutable Call{f} end
immutable AnyExpr end
immutable NoExpr end
immutable Lambda end

extrait(ex::Any) = NoExpr()
function extrait(ex::Expr)
    if iscall(ex)
        f = calle(ex)
        typeof(f) == Expr || return Call{f}()  # HACK: julia does not like expressions as type parameters
        return AnyExpr()
    elseif ismacrocall(ex)
        return MacroCall{calle(ex)}()
    elseif ex.head == Symbol("->")
        return Lambda()
    else
        return AnyExpr()
    end
end
