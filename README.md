# FactCheck2TestSets

If you want to migrate a package `MyPackage` from using FactCheck to TestSets, make sure that:
* You have the latest version of `MyPackage` installed.
* All tests of `MyPackage` pass.
* The repository of `MyPackge` contains no uncommited changes.

For the migration just run 
```
julia src/main.jl MyPackage
```

This will create a new branch in the Repository of `MyPackage` with FactCheck replaced by TestSets. 
Often there remain some small fixes, which you need to resolve by hand. For example multi line facts are not handled properly.
