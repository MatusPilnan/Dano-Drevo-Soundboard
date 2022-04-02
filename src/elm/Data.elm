module Data exposing (..)

import Json.Decode as D

type alias SoundID = String

type alias Sound =
  { title: String
  , id: SoundID
  , icon: Maybe String
  , sound: String
  }


soundDecoder =
  D.map4 (Sound)
    (D.field "title" D.string)
    (D.field "id" D.string)
    (D.maybe <| D.field "icon" D.string)
    (D.field "sound" D.string)


soundsDecoder = D.list soundDecoder

decodeSound jsonString =
  D.decodeString soundDecoder jsonString

decodeSounds json =
  D.decodeValue soundsDecoder json