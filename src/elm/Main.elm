port module Main exposing (..)

import Browser
import Html
import Html.Attributes as Attr
import Icons
import Dict exposing (Dict)
import Data exposing (SoundID, Sound)
import Json.Decode
import Http


port loadSounds : (Json.Decode.Value -> msg) -> Sub msg



type alias Model =
  { sounds : Dict SoundID Sound
  , apiBase : String
  }

type alias Flags =
  { apiBase : String
  }


type Msg
  = Noop
  | LoadedSounds (List Sound)
  | LoadingSoundsFailed


main : Program Flags Model Msg
main =
  Browser.element
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  }


init : Flags -> (Model, Cmd Msg)
init flags =
  ( { sounds = Dict.empty
    , apiBase = flags.apiBase
    }
  , fetchSounds flags.apiBase
  )


update : Msg -> Model -> (Model, Cmd Msg)
update msg model =
  case msg of
    Noop ->
      ( model, Cmd.none )
    LoadedSounds sounds ->
      ( { model
        | sounds = List.foldl (\newSound currentSounds -> Dict.insert newSound.id newSound currentSounds) model.sounds sounds
        }
      , Cmd.none
      )
    LoadingSoundsFailed ->
      ( model, Cmd.none )




view : Model -> Html.Html Msg
view model =
  Html.div 
  [ Attr.class "mt-16 pt-4 container mx-auto px-4" ] 
  [ Html.nav
    [ Attr.class "fixed top-0 right-0 left-0 bg-teal-600 h-16 shadow-lg flex justify-between items-center text-white" ]
    [ Html.a 
      [ Attr.href "#"
      , Attr.class "w-min ml-4"
      ]
      [ Html.text "DanoDrevo Soundboard" ]
    , Html.button [ Attr.class "m-4" ] [ Icons.menu ]
    ]
  , Html.ol
    [ Attr.class "grid gap-4 grid-cols-[repeat(auto-fit,minmax(100px,1fr))]" ]
    <| List.map (Html.li [ Attr.class "aspect-square" ] << List.singleton << soundboardButton model)
    <| List.sortBy .title
    <| Dict.values model.sounds
  ]


soundboardButton model sound =
  Html.button
  [ Attr.class "rounded-md bg-teal-100 hover:bg-teal-300 transition-colors w-full h-full p-4"
  ]
  [ Html.span 
    [ Attr.class "text-center" ]
    [ Html.text sound.title ]
  ]



fetchSounds basePath =
  Http.get 
  { url = basePath
  , expect = Http.expectJson
    (\ result ->
      case result of
        Result.Ok sounds ->
          LoadedSounds sounds
        Result.Err _ ->
          LoadingSoundsFailed
    )
    Data.soundsDecoder
  }



subscriptions : Model -> Sub Msg
subscriptions model =
  loadSounds 
  ( \jsonString ->
    case Data.decodeSounds jsonString of
      Result.Ok sounds ->
        LoadedSounds sounds
      Result.Err _ ->
        LoadedSounds []
  )