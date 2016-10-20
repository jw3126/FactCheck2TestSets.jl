const RNEXTLINE = r" # .*, line (\d*):"
typealias MaybeInt Nullable{Int}

lines(s::String) = split(s, "\n")
function has_linum(s::AbstractString)
    ismatch(RNEXTLINE, s)
end

function linum(s::AbstractString)
    if has_linum(s)
        i = parse(Int, match(RNEXTLINE, s)[1])
        return MaybeInt(i)
    else
        return MaybeInt()
    end
end

function purge_linum(s::AbstractString)
    has_linum(s) && return split(s, RNEXTLINE)[1]
    s
end

split_linum(l) = purge_linum(l), linum(l)
split_limums(s::AbstractString) = map(split_linum, lines(s))

maybe_linums(lines::Vector) = map(linum, lines)

function min_linums(maybe_nums::Vector{MaybeInt})
    min_numbers = Int[]
    min_linum = 1
    for maybe_i in maybe_nums
        push!(min_numbers, min_linum)
        if !(isnull(maybe_i))
            min_linum = get(maybe_i)
        end
    end
    min_numbers
end

const INF = typemax(Int64)
function max_linums(maybe_nums::Vector{MaybeInt})
    max_num = INF
    max_numbers = Int[]
    for maybe_i in reverse(maybe_nums)
        if !(isnull(maybe_i))
            max_num = get(maybe_i)
        end
        unshift!(max_numbers, max_num)
    end
    max_numbers
end

immutable LinePosition
    guess::Int
    lower::Int
    upper::Int
    exact::Bool
    function LinePosition(guess, lower, upper, exact)
        @assert 1 <= lower <= guess <= upper (lower, guess, upper)
        new(guess, lower, upper, exact)
    end
end

LinePosition(g::Int,l::Int,u::Int) = LinePosition(g,l,u, l == u)
LinePosition(i::Int) = LinePosition(i,i,i,true)

function linepositions{S <:AbstractString}(lines::Vector{S})
    mays = maybe_linums(lines)
    minis = min_linums(mays)
    maxis = max_linums(mays)
    positions = LinePosition[]

    last_mini = 0
    last_guess = 0
    N = length(minis)
    for i in 1:N
        mini = minis[i]
        maxi = maxis[i]
        if mini > last_mini
            pos = LinePosition(mini)
        else
            guess = clamp(last_guess+1, mini, maxi)
            pos = LinePosition(guess, mini, maxi)
        end
        last_guess = pos.guess
        last_mini = mini
        push!(positions, pos)
    end
    positions
end

hascomment(s::AbstractString) = length(split(s, '#')) > 1

function get_comment(s)
    @assert hascomment(s)
    split(s, '#', limit=2)[2]
end

function comment_dict{S <: AbstractString}(lines::Vector{S})
    ret = Dict{Int, String}()
    for i in 1:length(lines)
        l = lines[i]
        if hascomment(l)
            ret[i] = get_comment(l)
        end
    end
    ret
end

comment_dict(s::String) = s |> lines |> comment_dict

function extract!(d::Dict, key)
    val = d[key]
    delete!(d, key)
    val
end

function add_comments(lines, positions, com_dict::Dict)
    com_dict = deepcopy(com_dict)  # we eat it up
    ret = String[]
    for (line, pos) in zip(lines, positions)
        guess = pos.guess
        if guess in keys(com_dict)
            com = extract!(com_dict, guess)
            line = string(line, " #", com)
            push!(ret, line)
        else
            push!(ret, line)
        end
    end
    last_guess = positions[end].guess
    # after lines
    for key in com_dict |> keys |> collect |> sort
        @assert key > last_guess
        com = extract!(com_dict, key)
        val = string("#", com_dict[key])
        push!(ret, val)
    end
    @assert isempty(com_dict)
    ret
end

function fill_missing_lines_positions(ls, poss::Vector{LinePosition})
    N = length(ls)

    @assert N == length(poss)
    ls_ret = String[]
    poss_ret = LinePosition[]
    N == 0 && return ls_ret, poss_ret

    last_pos = first(poss)
    for i in 1:N
        next_line = ls[i]
        next_pos = poss[i]
        if next_pos.guess > last_pos.guess + 1 # missing lines
            lower = min(last_pos.lower, next_pos.lower)
            upper = max(last_pos.upper, next_pos.upper)
            l_missing = match(r"(\s*)", next_line)[1]  # current indentation level

            for missing in (last_pos.guess + 1) : (next_pos.guess -1)
                p_missing = LinePosition(missing, lower, upper)
                push!(poss_ret, p_missing)
                push!(ls_ret, l_missing)
            end
        end
        push!(poss_ret, next_pos)
        push!(ls_ret, next_line)
        last_pos = next_pos
    end
    ls_ret, poss_ret
end

tabs2spaces(s, n=4) = join(split(s, '\t'), " "^n)
unindent(s) = try return match(r"\s\s\s\s(.*)", tabs2spaces(s))[1] catch e error("cannot unindent $s") end

wrap_begin_end(s::String) = """begin
        $s
    end"""
function unwrap_begin_end(ls::Vector)
    @assert strip(ls[1]) == "begin" ls[1]
    @assert strip(ls[end]) == "end" ls[end]
    ret = ls[2:end-1]
    map(unindent, ret)
end

function transform_ast_preserving_comments(f,s::String)  # better name?
    s = wrap_begin_end(s)
    com_dict = comment_dict(s)
    ls_ret = s |> parse |> f |> string |> lines
    poss = linepositions(ls_ret)
    ls_ret = map(purge_linum, ls_ret)
    ls_ret, poss = fill_missing_lines_positions(ls_ret, poss)
    ls_ret = add_comments(ls_ret, poss, com_dict)
    ls_ret = unwrap_begin_end(ls_ret)
    map!(rstrip, ls_ret)
    join(ls_ret, "\n")
end
