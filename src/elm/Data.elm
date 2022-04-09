module Data exposing (..)

import Json.Decode as D
import Time
import Audio

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
  , isNew : Bool
  }


soundDecoder : D.Decoder Sound
soundDecoder =
  D.map4 (\a b c d -> Sound a b c d NotPlaying Nothing False)
    (D.field "title" D.string)
    (D.field "id" D.string)
    (D.maybe <| D.field "icon" D.string)
    (D.field "sound" D.string)


soundsDecoder : D.Decoder (List Sound)
soundsDecoder = D.list soundDecoder

decodeSound : String -> Result D.Error Sound
decodeSound jsonString =
  D.decodeString soundDecoder jsonString

decodeSounds : D.Value -> Result D.Error (List Sound)
decodeSounds json =
  D.decodeValue soundsDecoder json