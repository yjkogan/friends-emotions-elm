module Model.Friend exposing (..)

import Json.Decode as JSDecode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)

type alias Id = Int

type alias Color = String

type alias Friend =
    { name : String
    , id : Id
    , color : Color
    }

decodeFriend : JSDecode.Decoder Friend
decodeFriend =
  decode Friend
    |> required "name" JSDecode.string
    |> required "id" JSDecode.int
    |> required "color" JSDecode.string
