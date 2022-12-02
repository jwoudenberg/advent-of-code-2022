app "solution"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.1/zAoiC9xtQPHywYk350_b7ust04BmWLW00sjb9ZPtSQk.tar.br" }
    imports [pf.File, pf.Stdout, pf.Path, pf.Task]
    provides [main] to pf

main =
    result <- Task.attempt run
    when result is
        Ok _ -> Task.succeed {}
        Err err ->
            dbg
                err

            crash "Unexpected error"

run =
    input <- Task.await (File.readUtf8 (Path.fromStr "./day1/input"))

    elfCalories =
        Str.split input "\n\n"
        |> List.map (\str -> parseElf str |> List.sum)

    caloriesByMaxThreeElves =
        List.sortDesc elfCalories
        |> List.takeFirst 3
        |> List.sum

    Stdout.line (Num.toStr caloriesByMaxThreeElves)

parseElf = \str ->
    Str.split str "\n"
    |> List.keepIf (\x -> x != "")
    |> List.map parseOrCrash

parseOrCrash = \str ->
    when Str.toNat str is
        Ok n -> n
        Err _ -> crash "Cannot parse \(str) as a number"
