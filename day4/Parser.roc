interface Parser
    exposes [Parser, ParseError, run, str, any, map, with, many, byte, success, try, nat]
    imports []

Parser a := List U8 -> Result { result : a, remaining : List U8 } ParseError

ParseError : [
    BytesRemainAfterParsing (List U8),
    DidNotFindExpectedStr Str,
    NoParserInAnyMatched,
    UnexpectedEndOfBytes,
    ExpectedDigit U8,
]

run : List U8, Parser a -> Result a ParseError
run = \bytes, @Parser go ->
    { result, remaining } <- Result.try (go bytes)

    if
        List.isEmpty remaining
    then
        Ok result
    else
        Err (BytesRemainAfterParsing remaining)

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

fail : ParseError -> Parser a
fail = \err -> @Parser (\_ -> Err err)

byte : Parser U8
byte =
    @Parser (\bytes ->
      when List.first bytes is
        Ok result -> Ok { remaining: List.dropFirst bytes, result }
        Err _ -> Err UnexpectedEndOfBytes
    )

try : Parser a -> Parser (Result a ParseError)
try = \@Parser go ->
  @Parser (\bytes ->
    when go bytes is
      Ok { remaining, result } -> Ok { remaining, result: Ok result }
      Err err -> Ok { remaining: bytes, result: Err err }
  )

digit : Parser U8
digit =
  digitByte <- with byte
  if (digitByte >= 48) && (digitByte < 58)
    then success (digitByte - 48)
    else fail (ExpectedDigit digitByte)

nat : Parser Nat
nat =
  helper = \acc ->
    res <- with (try digit)
    when res is
      Ok next -> helper (10 * acc + Num.intCast next)
      Err _ -> success acc

  first <- with digit
  helper (Num.intCast first)
