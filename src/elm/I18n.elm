module I18n exposing (..)

type Locale
  = EN
  | SK

type Term
  = Version String
  | MarkAllSeen
  | SourceCode
  | RequestSound

i18n : Locale -> Term -> String
i18n locale term =
  case locale of
    EN ->
      case term of
        Version ver -> "Version " ++ ver
        MarkAllSeen -> "Mark all as seen"
        SourceCode -> "Source code"
        RequestSound -> "Request a new sound"

    SK ->
      case term of
        Version ver -> "Verzia " ++ ver
        MarkAllSeen -> "Označiť všetko ako videné"
        SourceCode -> "Zdrojový kód"
        RequestSound -> "Navrhnúť hlášku"


locales : List (String, Locale)
locales =
  [ ("EN", EN)
  , ("SK", SK)
  ]

decodeLocale : String -> Locale
decodeLocale code =
  case code of
    "en" -> EN
    "sk" -> SK
    _ -> SK


encodeLocale : Locale -> String
encodeLocale locale =
  case locale of
    EN -> "en"
    SK -> "sk"