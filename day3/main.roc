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
            |> groupsOf 3
            |> List.map groupPriority
            |> List.sum

    Stdout.line (Num.toStr totalPriority)

groupsOf : List a, Nat -> List (List a)
groupsOf = \originalList, size ->
    helper = \list,  acc ->
        if List.isEmpty list then
            acc
        else
            { before, others } = List.split list size
            helper others (List.append acc before)
    helper originalList []

allItems : Set (Int Unsigned8)
allItems =
    Str.toUtf8 "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ"
        |> Set.fromList

groupPriority : List Str -> Nat
groupPriority = \group ->
  commonItems = List.walk group allItems (\common, rucksack ->
    Set.intersection common (Set.fromList (Str.toUtf8 rucksack))
  )
  Set.toList commonItems
    |> List.map itemPriority
    |> List.sum

itemPriority : Int a -> Nat
itemPriority = \item ->
  if item > 96
    then Num.intCast (item - 96) # map a-z to 1-27
    else Num.intCast (item - 38) # map A-Z to 27-52
