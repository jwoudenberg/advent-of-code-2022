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
        File.readBytes (Path.fromStr "./day5/input")
        |> Task.mapFail FileError
        |> Task.await

    { ship } <-
        Parser.run input parser
        |> Result.mapErr ParseError
        |> Task.fromResult
        |> Task.await

    Stdout.line (Num.toStr (Dict.len ship))

Ship : Dict Nat (Stack Str)

Stack a : [Empty, Stack { top : a, rest : Stack a }]

Instruction : {
    amount : Nat,
    from : Nat,
    to : Nat,
}

parser : Parser.Parser { ship : Ship, instructions : List Instruction }
parser =
    shipParser : Parser.Parser Ship
    shipParser = shipParserHelper Dict.empty 1

    crateParser : Parser.Parser Str
    crateParser =
        byte <- Parser.with Parser.byte
        _ <- Parser.with (Parser.str "]")
        _ <- Parser.with (Parser.try (Parser.str " "))
        when Str.fromUtf8 [byte] is
            Ok str -> Parser.success str
            Err _ -> crash "unexpected UTF8 conversion problem"

    shipParserHelper : Ship, Nat -> Parser.Parser Ship
    shipParserHelper = \ship, stackIndex ->
        action <- Parser.with
                (
                    Parser.any [
                        Parser.str "[" |> Parser.map (\_ -> AddCrate),
                        Parser.str "    " |> Parser.map (\_ -> NextCol),
                        Parser.str "\n" |> Parser.map (\_ -> NextRow),
                        Parser.str " 1" |> Parser.map (\_ -> Done),
                    ]
                )
        when action is
            AddCrate ->
                crate <- Parser.with crateParser
                shipParserHelper (addCrate ship stackIndex crate) (stackIndex + 1)

            NextCol ->
                shipParserHelper ship (stackIndex + 1)

            NextRow ->
                shipParserHelper ship 1

            Done ->
                Parser.success ship

    instructionParser : Parser.Parser Instruction
    instructionParser =
        _ <- Parser.with (Parser.str "move ")
        amount <- Parser.with Parser.nat
        _ <- Parser.with (Parser.str " from ")
        from <- Parser.with Parser.nat
        _ <- Parser.with (Parser.str " to ")
        to <- Parser.with Parser.nat
        _ <- Parser.with (Parser.str "\n")
        Parser.success { amount, from, to }

    ship <- Parser.with shipParser
    _ <- Parser.with Parser.line
    _ <- Parser.with Parser.line
    instructions <- Parser.with (Parser.many instructionParser)
    Parser.success { ship, instructions }

prependStack : Stack a, a -> Stack a
prependStack = \stack, elem ->
    when stack is
        Empty -> Stack { top: elem, rest: Empty }
        Stack { top, rest } -> Stack { top, rest: prependStack rest elem }

addCrate : Ship, Nat, Str -> Ship
addCrate = \ship, stackIndex, crate ->
    stack = Dict.get ship stackIndex |> Result.withDefault Empty

    Dict.insert ship stackIndex (prependStack stack crate)
