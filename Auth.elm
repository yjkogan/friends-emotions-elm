module Auth exposing (..)

import Json.Decode as JSDecode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)

type alias AuthCredentials =
  { id : Int
  -- email : String
  -- password : String
}


decodeAuthCredentials : JSDecode.Decoder AuthCredentials
decodeAuthCredentials =
  decode AuthCredentials
    |> required "id" JSDecode.int
