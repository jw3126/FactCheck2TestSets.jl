const INTERESTING = ["Fact", "context"]

isinteresting(line::String) = map(INTERESTING) do keyword
    contains(line, keyword)
end |> any


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
end
