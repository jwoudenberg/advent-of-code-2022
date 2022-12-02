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
        File.readBytes (Path.fromStr "./day2/input")
        |> Task.mapFail FileError
        |> Task.await

    result <-
        Parser.run input (Parser.str "HI")
        |> Result.mapErr ParseError
        |> Task.fromResult
        |> Task.await

    Stdout.line result
