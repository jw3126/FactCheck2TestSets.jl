
iscall(ex::Expr) = ex.head == :call
iscall(x) = false
calle(ex::Expr) = (@assert iscall(ex); ex.args[1])
function callarg_unique(ex::Expr)
    argp = callargs(ex::Expr)
    @assert length(argp) == 1 ex
    return argp[1]
end

function callargs(ex::Expr)
    @assert iscall(ex)
    ex.args[2:end]
end
