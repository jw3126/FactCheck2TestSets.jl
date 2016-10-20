const SFACT = Symbol("@fact")
const SFACT_THROWS = Symbol("@fact_throws")

const COMPARISON_DICT = Dict(
:exactly               => Symbol("==="),
:less_than             => Symbol("<"),
:less_than_or_equal    => Symbol("<="),
:greater_than          => Symbol(">"),
:greater_than_or_equal => Symbol(">="),
)

const PROPERTIES = [:isnan, :isinf, :isfinite, :isodd, :iseven, :isempty]

"""
    fc2ts(x)

Convert expression like object x from FactCheck to TestSet.
"""
fc2ts(x) = x
fc2ts(x::Expr) = fc2ts(x, extrait(x))

function fc2ts(ex::Expr, ::MacroCall{SFACT})
     ex |> fact2testcore |> testex
end


function fc2ts(ex::Expr, ::Any)
    args = map(fc2ts, ex.args)
    return Expr(ex.head, args...)
end

function fc2ts(ex::Expr, ::MacroCall{SFACT_THROWS})
    args = ex.args[2:end]
    if length(args) == 1
        except = :Exception
        code = args[1]
    else
        @assert length(args) == 2
        except, code = args
    end
    :(@test_throws $except $code)
end

function fc2ts(ex::Expr, ::Call{:context})
    name, arg, body = name_arg_body(ex)
    body = fc2ts(body)
    :(@testset $arg $body)
end

function fc2ts(ex::Expr, ::Call{:facts})
    name, arg, body = name_arg_body(ex)
    body = fc2ts(body)
    :(@testset $arg $body)
end

function name_arg_body(doblock::Expr)
    @match doblock begin
        (name_)(arg_) do
            body_
        end => (name, arg, body)
    end
end


fact2testcore(ex) = lhs_rhs2testcore(lhs_rhs(ex)...)

function lhs_rhs(ex)
    @match ex begin
        @fact(lhs_ --> rhs_) => (lhs, rhs)
    end
end

testex(args...) = Expr(:macrocall, Symbol("@test"), args...)

lhs_rhs2testcore(lhs, rhs) = lhs_rhs2testcore(lhs, rhs, extrait(rhs))
lhs_rhs2testcore(lhs, rhs, rtrait) = :($lhs == $rhs)
lhs_rhs2testcore(lhs, rhs::Bool, ::NoExpr) = rhs ? lhs : :(!$lhs)

function lhs_rhs2testcore(lhs, rhs::Symbol, ::NoExpr)
    if rhs in PROPERTIES
        return :($rhs($lhs))
    else
        return :($lhs == $rhs)
    end
end

function lhs_rhs2testcore(lhs, rhs::Expr, ::Call{:not})
    @assert rhs.args[1] == :not
    rhs_new = callarg_unique(rhs)
    ex = lhs_rhs2testcore(lhs, rhs_new)
    :(!$ex)
end

atol2kw(x) = Expr(:kw, :atol, x)
function atol2kw(x::Expr)
    x.head == :kw && return x
    return Expr(:kw, :atol, x)
end

function lhs_rhs2testcore(lhs, rhs::Expr, ::Call{:roughly})
    args = callargs(rhs)
    arg = args[1]
    kw = map(atol2kw, args[2:end])
    if length(args) == 1
        return :($lhs ≈ $arg)
    else
        return Expr(:call, :isapprox, lhs, arg, kw...)
    end
end

function lhs_rhs2testcore{f}(lhs, rhs::Expr, ::Call{f})
    if f in keys(COMPARISON_DICT)
        s = COMPARISON_DICT[f]
        rhs_new = callarg_unique(rhs)
        return Expr(:call, s, lhs, rhs_new)
    else
        return :($lhs == $rhs)
    end
end

function lhs_rhs2testcore(lhs, rhs::Expr, ::Lambda)
    Expr(:call, rhs, lhs)
end
