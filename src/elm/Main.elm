port module Main exposing (..)

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
import Set exposing (Set)


port loadSounds : (Json.Decode.Value -> msg) -> Sub msg
port audioPortToJS : Json.Encode.Value -> Cmd msg
port audioPortFromJS : (Json.Decode.Value -> msg) -> Sub msg
port newSoundPlayed : List SoundID -> Cmd msg



type alias Model =
  { sounds : Dict SoundID Sound
  , apiBase : String
  , knownSounds : Set SoundID
  , menuOpen : Bool
  , version : String
  }

type alias Flags =
  { apiBase : String
  , knownSounds : List SoundID
  }


type Msg
  = Noop
  | LoadedSounds (List Sound)
  | LoadingSoundsFailed
  | Play Sound Time.Posix
  | StartPlaying Sound
  | StopPlaying Sound
  | AudioLoaded Sound Audio.Source
  | SetMenuOpen Bool
  | MarkAllSoundsAsSeen


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
    , knownSounds = Set.fromList flags.knownSounds
    , menuOpen = False
    , version = "Version 1.1.1"
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
      let 
        newSounds =
          List.foldl 
          (\newSound currentSounds ->
            Dict.insert newSound.id { newSound | isNew = isSoundNew model.knownSounds newSound } currentSounds
          ) 
          model.sounds 
          sounds
      in
      ( { model
        | sounds = newSounds
        }
      , Cmd.none
      , Audio.cmdBatch 
        <| List.map 
          (\s -> Audio.loadAudio (processAudioLoadingResult { s | isNew = isSoundNew model.knownSounds s }) <| model.apiBase ++ s.sound) 
          sounds
      )
    LoadingSoundsFailed ->
      ( model, Cmd.none, Audio.cmdNone )
    Play sound startTime ->
      let newSound = { sound | state = Data.Playing startTime, isNew = False } in
      ( { model
        | sounds = 
          Dict.insert sound.id newSound model.sounds
        , knownSounds = Set.insert sound.id model.knownSounds
        }
      , Cmd.batch
        [ sound.audioSource
          |> Maybe.map (Audio.length audioData)
          |> Maybe.map Duration.inMilliseconds
          |> Maybe.map Process.sleep
          |> Maybe.map (Task.perform <| always <| StopPlaying newSound)
          |> Maybe.withDefault Cmd.none
        , if isSoundNew model.knownSounds sound then newSoundPlayed [ sound.id ] else Cmd.none
        ]
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
                  (Data.NotPlaying, Data.Playing _) -> Just { sound | state = Data.NotPlaying } 
          ) model.sounds
        }
      , Cmd.none
      , Audio.cmdNone
      )
    AudioLoaded sound source ->
      ( { model
        | sounds = 
          Dict.update sound.id
          (\existing ->
            case existing of
              Nothing -> Just { sound | audioSource = Just source }
              Just s -> Just { s | audioSource = Just source }
          )
          model.sounds
        }
      , Cmd.none
      , Audio.cmdNone 
      )
    SetMenuOpen open ->
      ( { model | menuOpen = open }
      , Cmd.none
      , Audio.cmdNone
      )
    MarkAllSoundsAsSeen ->
      ( { model
        | sounds = Dict.map (\_ sound -> { sound | isNew = False }) model.sounds
        , knownSounds = Set.union model.knownSounds (Set.fromList <| List.map .id <| Dict.values model.sounds)
        }
      , newSoundPlayed <| List.filterMap (\sound -> if Set.member sound.id model.knownSounds then Nothing else Just sound.id) <| Dict.values model.sounds
      , Audio.cmdNone
      )


isSoundNew : Set SoundID -> Sound-> Bool
isSoundNew knownSounds sound =
  not <| Set.member sound.id knownSounds


processAudioLoadingResult : Sound -> Result Audio.LoadError Audio.Source -> Msg
processAudioLoadingResult sound result =
  case result of
    Result.Ok source ->
      AudioLoaded sound source
    Result.Err _ ->
      Noop


audio: Audio.AudioData -> Model -> Audio.Audio
audio _ model =
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
view _ model =
  Html.div 
  [ Attr.class "my-16 py-4 container mx-auto px-4" ] 
  [ Html.nav
    [ Attr.class "fixed z-10 top-0 right-0 left-0 bg-teal-600 h-16 shadow-lg flex justify-between items-center text-white" ]
    [ Html.a 
      [ Attr.href "#"
      , Attr.class "w-min ml-4"
      ]
      [ Html.text "DanoDrevo Soundboard" ]
    , Html.button [ Attr.class "m-4", Events.onClick <| SetMenuOpen True ] [ Icons.menu ]
    , menuDrawer model
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
  [ Attr.class "rounded-md h-full w-full relative z-0"
  , Events.onClick <| if isPlaying sound then StopPlaying sound else StartPlaying sound
  ] <|
  ( case sound.icon of
    Nothing -> []
    Just icon ->
      [ Html.img
        [ Attr.class "absolute top-0 bottom-0 right-0 left-0 w-full h-full object-cover -z-10 rounded-md"
        , Attr.src <| model.apiBase ++ icon
        ]
        []
      ]
  ) ++
  [ Html.div 
    [ Attr.class "text-center md:hover:bg-teal-600 transition-colors rounded-md"
    , Attr.class "w-full h-full p-4 text-sm font-light flex items-center justify-center"
    , Attr.classList 
      [("before:rounded-full before:h-2 before:w-2 before:-top-0.5 before:-right-0.5 before:absolute before:bg-teal-600 before:animate-ping", sound.isNew)]
    , Attr.classList
      [ ("md:hover:text-white ", m sound.icon)
      , ("bg-teal-100 bg-opacity-90 md:hover:bg-opacity-50", not <| isPlaying sound)
      , ("bg-teal-300 bg-opacity-50 md:hover:bg-opacity-75", isPlaying sound)
      , ("text-white", isPlaying sound && m sound.icon)
      ]
    ]
    [ Html.span [] [ Html.text sound.title ] ]
  ]


menuDrawer : Model -> Html.Html Msg
menuDrawer model =
  Html.div
  [ Attr.class "fixed" ]
  [ Html.div
    [ Attr.class "fixed transition-all bg-black opacity-0"
    , Attr.classList
      [("top-0 bottom-0 left-0 right-0 h-full opacity-50", model.menuOpen)]
    , Events.onClick <| SetMenuOpen False
    ]
    []
  , Html.div
    [ Attr.class "fixed w-64 max-w-screen top-0 bottom-0 bg-white shadow-lg transition-all text-black"
    , Attr.classList
      [ ("right-0", model.menuOpen)
      , ("-right-64 ", not model.menuOpen)
      ]
    ]
    [ Html.div
      [ Attr.class "h-16 w-full flex justify-between items-center border-b border-gray-200 px-4" ]
      [ Html.div
        []
        [ Html.h1
          [ Attr.class "font-bold" ]
          [ Html.text "Dano Drevo SB" ]
        , Html.p
          [ Attr.class "font-light text-xs text-gray-500" ]
          [ Html.text model.version ]
        ]
      , Html.button
        [ Events.onClick <| SetMenuOpen False ]
        [ Icons.close ]
      ]
    , if List.any .isNew <| Dict.values model.sounds then menuButton "Mark all as seen" MarkAllSoundsAsSeen Icons.check else Html.text ""
    ]
  ]

menuButton : String -> Msg -> Html.Html Msg -> Html.Html Msg
menuButton text onClick icon =
  Html.button
  [ Attr.class "hover:bg-teal-100 hover:text-teal-600 border-b border-gray-200 w-full transition-colors h-14 text-left px-4 flex justify-between items-center" 
  , Events.onClick onClick
  ]
  [ Html.span [] [ Html.text text ] 
  , icon
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
subscriptions _ _ =
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