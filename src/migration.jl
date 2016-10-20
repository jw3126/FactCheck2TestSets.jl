const INTERESTING = ["Fact", "context"]

isinteresting(line::String) = map(INTERESTING) do keyword
    contains(line, keyword)
end |> any

function migrate_string(s::String)
    transform_ast_preserving_comments(fc2ts,s)
end

function convert_file(path)
    @assert isjl(path)
    lines = readlines(path)
    lines = map(convert_line, lines)
    txt = join(lines, "\n")
    write(path, txt)
end

function convert_folder(root)
    walkpaths(root) do path
        isjl(path) && convert_file(path)
    end
end

function migrate_REQUIRE_string(path)
    if ispath(path)
        lines = readlines(path)
    else
        lines = [""]
    end
    f(line) = strip(line) in ["FactCheck", "BaseTestNext"] ? "" : line
    map!(f, lines)
    push!(lines, "BaseTestNext\n")
    join(lines)
end

function migrate_REQUIRE(path)
    txt = migrate_REQUIRE_string(path)
    write(path, txt)
end

function convert_pkg(pkgname; checkout=false, install=false, reset_hard=false)
    install && Pkg.add(pkgname)
    checkout && Pkg.checkout(pkgname)
    pkgdir = Pkg.dir(pkgname)
    cd(pkgdir)
    reset_hard && run(`git reset --hard`)
    branch = "hellotestsets"
    try run(`git branch $branch`) catch e println(e) end
    sleep(0.1)
    run(`git checkout $branch`)
    sleep(0.1)
    test_path = joinpath(pkgdir, "test")
    convert_folder(test_path)
    migrate_REQUIRE(joinpath(test_path, "REQUIRE"))
end
