function lhs_rhs(ex)
    @match ex begin
        @fact(lhs_ --> rhs_) => (lhs, rhs)
    end
end

testex(args...) = Expr(:macrocall, Symbol("@test"), args...)

fact2testcore(factex) = lhs_rhs2testcore(lhs_rhs(factex)...)

const COMPARISON_DICT = Dict(
:exactly               => Symbol("==="),
:less_than             => Symbol("<"),
:less_than_or_equal    => Symbol("<="),
:greater_than          => Symbol(">"),
:greater_than_or_equal => Symbol(">="),
)

const PROPERTIES = [:isnan, :isinf, :isfinite, :isodd, :iseven]

function lhs_rhs2testcore_not(lhs, rhs)
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

function lhs_rhs2testcore_roughly(lhs, rhs)
    args = callargs(rhs)
    arg = args[1]
    kw = map(atol2kw, args[2:end])
    if length(args) == 1
        return :($lhs ≈ $arg)
    else
        return Expr(:call, :isapprox, lhs, arg, kw...)
    end
end

function lhs_rhs2testcore(lhs, rhs)
    if rhs == true
        return lhs
    elseif rhs == false
        return :(!$lhs)
    elseif rhs in PROPERTIES
        return :($rhs($lhs))
    elseif iscall(rhs)
        f = calle(rhs)
        if f == :not
            return lhs_rhs2testcore_not(lhs, rhs)
        elseif f == :roughly
            return lhs_rhs2testcore_roughly(lhs, rhs)
        elseif f in keys(COMPARISON_DICT)
            s = COMPARISON_DICT[f]
            rhs_new = callarg_unique(rhs)
            return Expr(:call, s, lhs, rhs_new)
        end
        return :($lhs == $rhs)
    else
        return :($lhs == $rhs)
    end
end

function fact_throws2test_throws(ex::Expr)
    @assert ex.head == :macrocall
    @assert ex.args[1] == Symbol("@fact_throws")
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
