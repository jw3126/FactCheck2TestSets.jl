const RSTRINGMACRO = r"@([^\s\(\)]*)_str\((\"[^\"]*\")\)"  # care about triple quotes?
function sugar_stringmacro(s)
    m = match(RSTRINGMACRO, s)
    string(m[1], m[2])
end
function sugar_stringmacros(s)
    replace(s, RSTRINGMACRO, sugar_stringmacro)
end


function sugar(s)
    sugar_stringmacros(s)
end
