interface Parser
    exposes [Parser, ParseError, run, str, any, map, with, many, success]
    imports []

Parser a := List U8 -> Result { result : a, remaining : List U8 } ParseError

ParseError : [
    BytesRemainAfterParsing (List U8),
    DidNotFindExpectedStr Str,
    NoParserInAnyMatched,
]

run : List U8, Parser a -> Result a ParseError
run = \bytes, @Parser go ->
    { result, remaining } <- Result.try (go bytes)

    if
        List.isEmpty remaining
    then
        Ok result
    else
        # Err (BytesRemainAfterParsing remaining)
        Ok result

str : Str -> Parser Str
str = \expected ->
    expectedBytes = Str.toUtf8 expected
    size = List.len expectedBytes

    @Parser
        (\bytes ->
            if
                List.takeFirst bytes size == expectedBytes
            then
                Ok { result: expected, remaining: List.drop bytes size }
            else
                Err (DidNotFindExpectedStr expected)
        )

any : List (Parser a) -> Parser a
any = \parsers ->
    @Parser
        (\bytes ->
            step = \failResult, @Parser go ->
                when go bytes is
                    Ok res -> Break (Ok res)
                    Err _ -> Continue failResult

            List.walkUntil parsers (Err NoParserInAnyMatched) step
        )

map : Parser a, (a -> b) -> Parser b
map = \@Parser go, f ->
    @Parser
        (\bytes ->
            { result, remaining } <- Result.try (go bytes)
            Ok { remaining, result: f result }
        )

with : Parser a, (a -> Parser b) -> Parser b
with = \@Parser go, next ->
    @Parser
        (\bytes ->
            { result, remaining } <- Result.try (go bytes)
            (@Parser goNext) = next result

            goNext remaining
        )

many : Parser a -> Parser (List a)
many = \parser ->
    first <- with parser
    @Parser (\bytes -> manyHelper parser [first] bytes)

manyHelper = \parser, acc, bytes ->
    @Parser go = parser
    when go bytes is
        Ok { result, remaining } ->
            manyHelper parser (List.append acc result) remaining

        Err _ ->
            Ok { remaining: bytes, result: acc }

success : a -> Parser a
success = \result -> @Parser (\remaining -> Ok { remaining, result })
