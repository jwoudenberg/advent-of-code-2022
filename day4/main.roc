app "solution"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.1/zAoiC9xtQPHywYk350_b7ust04BmWLW00sjb9ZPtSQk.tar.br" }
    imports [pf.File, pf.Stdout, pf.Path, pf.Task, Parser]
    provides [main] to pf

main =
    result <- Task.attempt run
    when result is
        Ok _ -> Task.succeed {}
        Err _ -> crash "Unexpected error"

run =
    input <-
        File.readBytes (Path.fromStr "./day4/input")
        |> Task.mapFail FileError
        |> Task.await

    workAssignments <-
        Parser.run input parser
        |> Result.mapErr ParseError
        |> Task.fromResult
        |> Task.await

    overlappingWorkAssignments =
        List.keepIf workAssignments overlaps

    Stdout.line (Num.toStr (List.len overlappingWorkAssignments))

WorkAssignment : {
    elf1 : { start : Nat, end : Nat },
    elf2 : { start : Nat, end : Nat },
}

overlaps : WorkAssignment -> Bool
overlaps = \{ elf1, elf2 } ->
    !((elf1.start > elf2.end) || (elf1.end < elf2.start))

parser : Parser.Parser (List WorkAssignment)
parser =
    rangeParser : Parser.Parser { start : Nat, end : Nat }
    rangeParser =
        start <- Parser.with Parser.nat
        _ <- Parser.with (Parser.str "-")
        end <- Parser.with Parser.nat
        Parser.success { start, end }

    workAssignmentParser : Parser.Parser WorkAssignment
    workAssignmentParser =
        elf1 <- Parser.with rangeParser
        _ <- Parser.with (Parser.str ",")
        elf2 <- Parser.with rangeParser
        _ <- Parser.with (Parser.str "\n")
        Parser.success { elf1, elf2 }

    Parser.many workAssignmentParser
