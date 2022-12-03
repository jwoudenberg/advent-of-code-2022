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
    input <- Task.await (File.readUtf8 (Path.fromStr "./day3/input"))

    totalPriority =
        Str.split input "\n"
            |> List.map rucksackPriority
            |> List.sum

    Stdout.line (Num.toStr totalPriority)

rucksackPriority : Str -> Nat
rucksackPriority = \rucksack ->
  items = Str.toUtf8 rucksack
  compartmentSize = List.len items // 2
  { before, others } = List.split items compartmentSize
  commonItems = Set.intersection (Set.fromList before) (Set.fromList others)
  Set.toList commonItems
    |> List.map itemPriority
    |> List.sum

itemPriority : Int a -> Nat
itemPriority = \item ->
  if item > 96
    then Num.intCast (item - 96) # map a-z to 1-27
    else Num.intCast (item - 38) # map A-Z to 27-52
