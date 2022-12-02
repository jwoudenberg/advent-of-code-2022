app "solution"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.1/zAoiC9xtQPHywYk350_b7ust04BmWLW00sjb9ZPtSQk.tar.br" }
    imports [pf.File, pf.Stdout, pf.Path, pf.Task, Parser]
    provides [main] to pf

main =
    result <- Task.attempt run
    when result is
        Ok _ -> Task.succeed {}
        Err _ -> crash "Unexpected error"

Game : { opponent : [A, B, C], self : [X, Y, Z] }

run =
    input <-
        File.readBytes (Path.fromStr "./day2/input")
        |> Task.mapFail FileError
        |> Task.await

    games <-
        Parser.run input parser
        |> Result.mapErr ParseError
        |> Task.fromResult
        |> Task.await

    totalScore = List.map games score |> List.sum

    Stdout.line (Num.toStr totalScore)

score : Game -> Nat
score = \game ->
    pointsFromOutcome =
        when outcome game is
            Win -> 6
            Draw -> 3
            Loss -> 0

    pointsFromMove =
        when fromSelf game.self is
            Rock -> 1
            Paper -> 2
            Scissors -> 3

    pointsFromOutcome + pointsFromMove

outcome : Game -> [Win, Draw, Loss]
outcome = \game ->
    when { opponent: fromOpponent game.opponent, self: fromSelf game.self } is
        { opponent: Rock, self: Rock } -> Draw
        { opponent: Rock, self: Paper } -> Win
        { opponent: Rock, self: Scissors } -> Loss
        { opponent: Paper, self: Rock } -> Loss
        { opponent: Paper, self: Paper } -> Draw
        { opponent: Paper, self: Scissors } -> Win
        { opponent: Scissors, self: Rock } -> Win
        { opponent: Scissors, self: Paper } -> Loss
        { opponent: Scissors, self: Scissors } -> Draw

fromOpponent : [A, B, C] -> [Rock, Paper, Scissors]
fromOpponent = \move ->
    when move is
        A -> Rock
        B -> Paper
        C -> Scissors

fromSelf : [X, Y, Z] -> [Rock, Paper, Scissors]
fromSelf = \move ->
    when move is
        X -> Rock
        Y -> Paper
        Z -> Scissors

parser : Parser.Parser (List Game)
parser =
    opponentParser =
        Parser.any [
            Parser.str "A" |> Parser.map (\_ -> A),
            Parser.str "B" |> Parser.map (\_ -> B),
            Parser.str "C" |> Parser.map (\_ -> C),
        ]

    selfParser =
        Parser.any [
            Parser.str "X" |> Parser.map (\_ -> X),
            Parser.str "Y" |> Parser.map (\_ -> Y),
            Parser.str "Z" |> Parser.map (\_ -> Z),
        ]

    gameParser =
        opponent <- Parser.with opponentParser
        _ <- Parser.with (Parser.str " ")
        self <- Parser.with selfParser
        _ <- Parser.with (Parser.str "\n")
        Parser.success { opponent, self }

    Parser.many gameParser
