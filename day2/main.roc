app "solution"
    packages { pf: "https://github.com/roc-lang/basic-cli/releases/download/0.1.1/zAoiC9xtQPHywYk350_b7ust04BmWLW00sjb9ZPtSQk.tar.br" }
    imports [pf.File, pf.Stdout, pf.Path, pf.Task, Parser]
    provides [main] to pf

main =
    result <- Task.attempt run
    when result is
        Ok _ -> Task.succeed {}
        Err _ -> crash "Unexpected error"

Guide : { opponent : [A, B, C], play : [X, Y, Z] }

run =
    input <-
        File.readBytes (Path.fromStr "./day2/input")
        |> Task.mapFail FileError
        |> Task.await

    guides <-
        Parser.run input parser
        |> Result.mapErr ParseError
        |> Task.fromResult
        |> Task.await

    totalScore = List.map guides score |> List.sum

    Stdout.line (Num.toStr totalScore)

score : Guide -> Nat
score = \guide ->
    pointsFromOutcome =
        when fromPlay guide.play is
            Win -> 6
            Draw -> 3
            Lose -> 0

    pointsFromMove =
        when selfMove guide is
            Rock -> 1
            Paper -> 2
            Scissors -> 3

    pointsFromOutcome + pointsFromMove

selfMove : Guide -> [Rock, Paper, Scissors]
selfMove = \guide ->
    when { opponent: fromOpponent guide.opponent, intent: fromPlay guide.play } is
        { opponent: Rock, intent: Lose } -> Scissors
        { opponent: Rock, intent: Draw } -> Rock
        { opponent: Rock, intent: Win } -> Paper
        { opponent: Paper, intent: Lose } -> Rock
        { opponent: Paper, intent: Draw } -> Paper
        { opponent: Paper, intent: Win } -> Scissors
        { opponent: Scissors, intent: Lose } -> Paper
        { opponent: Scissors, intent: Draw } -> Scissors
        { opponent: Scissors, intent: Win } -> Rock

fromOpponent : [A, B, C] -> [Rock, Paper, Scissors]
fromOpponent = \move ->
    when move is
        A -> Rock
        B -> Paper
        C -> Scissors

fromPlay : [X, Y, Z] -> [Lose, Draw, Win]
fromPlay = \play ->
    when play is
        X -> Lose
        Y -> Draw
        Z -> Win

parser : Parser.Parser (List Guide)
parser =
    opponentParser =
        Parser.any [
            Parser.str "A" |> Parser.map (\_ -> A),
            Parser.str "B" |> Parser.map (\_ -> B),
            Parser.str "C" |> Parser.map (\_ -> C),
        ]

    playParser =
        Parser.any [
            Parser.str "X" |> Parser.map (\_ -> X),
            Parser.str "Y" |> Parser.map (\_ -> Y),
            Parser.str "Z" |> Parser.map (\_ -> Z),
        ]

    gameParser =
        opponent <- Parser.with opponentParser
        _ <- Parser.with (Parser.str " ")
        play <- Parser.with playParser
        _ <- Parser.with (Parser.str "\n")
        Parser.success { opponent, play }

    Parser.many gameParser
