port module Main exposing (..)

import Browser
import Html
import Html.Attributes as Attr
import Html.Events as Events
import Icons
import Dict exposing (Dict)
import Data exposing (SoundID, Sound)
import Json.Decode
import Json.Encode
import Http
import Audio
import Task
import Time
import Process
import Duration


port loadSounds : (Json.Decode.Value -> msg) -> Sub msg
port audioPortToJS : Json.Encode.Value -> Cmd msg
port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg



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
  | Play Sound Time.Posix
  | StartPlaying Sound
  | StopPlaying Sound
  | AudioLoaded Sound Audio.Source


main : Platform.Program Flags (Audio.Model Msg Model) (Audio.Msg Msg)
main =
  Audio.elementWithAudio
  { init = init
  , view = view
  , update = update
  , subscriptions = subscriptions
  , audio = audio
  , audioPort = { toJS = audioPortToJS, fromJS = audioPortFromJS }
  }


init : Flags -> (Model, Cmd Msg, Audio.AudioCmd Msg)
init flags =
  ( { sounds = Dict.empty
    , apiBase = flags.apiBase
    }
  , fetchSounds flags.apiBase
  , Audio.cmdNone
  )


update : Audio.AudioData -> Msg -> Model -> (Model, Cmd Msg, Audio.AudioCmd Msg)
update audioData msg model =
  case msg of
    Noop ->
      ( model, Cmd.none, Audio.cmdNone )
    LoadedSounds sounds ->
      ( { model
        | sounds = List.foldl (\newSound currentSounds -> Dict.insert newSound.id newSound currentSounds) model.sounds sounds
        }
      , Cmd.none
      , Audio.cmdBatch <| List.map (\s -> Audio.loadAudio (processAudioLoadingResult s) <| model.apiBase ++ s.sound) sounds
      )
    LoadingSoundsFailed ->
      ( model, Cmd.none, Audio.cmdNone )
    Play sound startTime ->
      let newSound = { sound | state = Data.Playing startTime } in
      ( { model
        | sounds = 
          Dict.insert sound.id newSound model.sounds
        }
      , sound.audioSource
        |> Maybe.map (Audio.length audioData)
        |> Maybe.map Duration.inMilliseconds
        |> Maybe.map Process.sleep
        |> Maybe.map (Task.perform <| always <| StopPlaying newSound)
        |> Maybe.withDefault Cmd.none
      , Audio.cmdNone 
      )
    StartPlaying sound ->
      ( model
      , Task.perform (Play sound) Time.now
      , Audio.cmdNone 
      )
    StopPlaying sound ->
      ( { model
        | sounds = 
          Dict.update sound.id
          ( \current ->
            case current of
              Nothing -> Just { sound | state = Data.NotPlaying }
              Just currentSound ->
                case (currentSound.state, sound.state) of
                  (Data.NotPlaying, Data.NotPlaying) -> Just sound
                  (Data.Playing _, Data.NotPlaying) -> Just sound 
                  (Data.Playing startTime1, Data.Playing startTime2) -> 
                    if (Time.posixToMillis startTime1) > (Time.posixToMillis startTime2)
                    then Just currentSound 
                    else Just { sound | state = Data.NotPlaying } 
                  (Data.NotPlaying, Data.Playing startTime) -> Just { sound | state = Data.NotPlaying } 
          ) model.sounds
        }
      , Cmd.none
      , Audio.cmdNone
      )
    AudioLoaded sound source ->
      ( { model
        | sounds = 
          Dict.insert sound.id
          { sound | audioSource = Just source }
          model.sounds
        }
      , Cmd.none
      , Audio.cmdNone 
      )


processAudioLoadingResult : Sound -> Result Audio.LoadError Audio.Source -> Msg
processAudioLoadingResult sound result =
  case result of
    Result.Ok source ->
      AudioLoaded sound source
    Result.Err e ->
      Noop


audio: Audio.AudioData -> Model -> Audio.Audio
audio audioData model =
  Dict.values model.sounds
  |> List.filterMap
    (\sound ->
      case (sound.state, sound.audioSource) of
        (Data.Playing since, Just source) ->
          Just <| Audio.audio source since
        (_, _) -> Nothing
    )
  |> Audio.group

view : Audio.AudioData -> Model -> Html.Html Msg
view audioData model =
  Html.div 
  [ Attr.class "my-16 py-4 container mx-auto px-4" ] 
  [ Html.nav
    [ Attr.class "fixed z-10 top-0 right-0 left-0 bg-teal-600 h-16 shadow-lg flex justify-between items-center text-white" ]
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


soundboardButton : Model -> Sound -> Html.Html Msg
soundboardButton model sound =
  Html.button
  [ Attr.class "rounded-md h-full w-full relative z-0 overflow-hidden"
  , Events.onClick <| if isPlaying sound then StopPlaying sound else StartPlaying sound
  ] <|
  ( case sound.icon of
    Nothing -> []
    Just icon ->
      [ Html.img
        [ Attr.class "absolute top-0 bottom-0 right-0 left-0 w-full h-full object-cover -z-10"
        , Attr.src <| model.apiBase ++ icon
        ]
        []
      ]
  ) ++
  [ Html.div 
    [ Attr.class "text-center hover:bg-teal-600 transition-colors"
    , Attr.class "w-full h-full p-4 text-sm font-light flex items-center justify-center" 
    , Attr.classList
      [ ("hover:text-white ", m sound.icon)
      , ("bg-teal-100 bg-opacity-90 hover:bg-opacity-50", not <| isPlaying sound)
      , ("bg-teal-300 bg-opacity-50 hover:bg-opacity-75", isPlaying sound)
      , ("text-white", isPlaying sound && m sound.icon)
      ]
    ]
    [ Html.span [] [ Html.text sound.title ] ]
  ]

isPlaying : Sound -> Bool
isPlaying sound =
  case sound.state of
    Data.Playing _ -> True
    Data.NotPlaying -> False

fetchSounds : String -> Cmd Msg
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



subscriptions : Audio.AudioData -> Model -> Sub Msg
subscriptions audioData model =
  loadSounds 
  ( \jsonString ->
    case Data.decodeSounds jsonString of
      Result.Ok sounds ->
        LoadedSounds sounds
      Result.Err _ ->
        LoadedSounds []
  )


m : Maybe a -> Bool
m maybe =
  case maybe of
    Nothing -> False
    Just _ -> True