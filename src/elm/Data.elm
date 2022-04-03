module Data exposing (..)

import Json.Decode as D
import Time
import Audio exposing (Audio)

type alias SoundID = String

type SoundState
  = NotPlaying
  | Playing Time.Posix


type alias Sound =
  { title : String
  , id : SoundID
  , icon : Maybe String
  , sound : String
  , state : SoundState
  , audioSource : Maybe Audio.Source
  }


soundDecoder =
  D.map4 (\a b c d -> Sound a b c d NotPlaying Nothing)
    (D.field "title" D.string)
    (D.field "id" D.string)
    (D.maybe <| D.field "icon" D.string)
    (D.field "sound" D.string)


soundsDecoder = D.list soundDecoder

decodeSound jsonString =
  D.decodeString soundDecoder jsonString

decodeSounds json =
  D.decodeValue soundsDecoder json