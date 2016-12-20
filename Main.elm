port module Main exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html
import Html.Attributes as Attrs
import Html.Events exposing (onInput)
import Http
import Json.Decode as JSDecode
import Json.Decode.Pipeline exposing (decode, required, optional, hardcoded)
import Json.Encode as JSEncode
import List
import WebSocket

import Auth exposing (AuthCredentials)
import Friends
import Model.Friend as Friend exposing (Friend)

websocketAddress : String
websocketAddress = "ws://localhost:1234"

main : Program Never Model Msg
main =
    Html.program
        { init = (init, Cmd.none)
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


-- model

type alias Model =
    { friends : Dict Friend.Id Friend
    , myself : Friend
    }

init : Model
init =
    { friends = Dict.fromList
          [ (1, { name = "Yoni", id = 1, color = "blue" })
          , (2, { name = "Molly", id = 2, color = "purple" })
          , (3, { name = "Dan", id = 3, color = "orange" })
          , (4, { name = "Elise", id = 4, color = "brown" })
          ]
    , myself = initialSelf
    }

initialSelf : Friend
initialSelf =
    { name = "Kirk"
    , id = 0
    , color = "blue"
    }

-- messages

type Msg
    = FriendUpdate Friend.Id Friend.Color
    | UpdateMyself Friend.Color
    | Login AuthCredentials
    | FriendHttpResponse Friends.FriendHttpMsg
    | GotError

update : Msg -> Model -> (Model, Cmd Msg)
update msg ({ friends, myself } as model) =
    case msg of
        FriendUpdate id color ->
            { myself = myself
            , friends = Dict.update id (Maybe.map (\f -> { f | color = color })) friends
            } ! []
        UpdateMyself color ->
            let jsonMessage = JSEncode.object
                                [ ("FriendUpdate", JSEncode.object
                                    [ ("id", JSEncode.int myself.id)
                                    , ("color", JSEncode.string color)
                                    ]
                                  )
                                ]
            in
              ({ friends = friends
              , myself = { myself | color = color }
              }, WebSocket.send websocketAddress (JSEncode.encode 0 jsonMessage))
        Login { id } ->
            (model, Cmd.map FriendHttpResponse (Friends.getUserWithId id))
        FriendHttpResponse (Friends.ReceivedLoggedInUser result) ->
          case result of
            Err error -> model ! []
            Ok loggedInUser ->
              ({ friends = Dict.empty, myself = loggedInUser }, Cmd.map FriendHttpResponse (Friends.getFriendsForUserWithId (Debug.log "loggedInUser.id" loggedInUser.id)))
        FriendHttpResponse (Friends.ReceivedFriendsForLoggedInUser result) ->
          case result of
            Err error -> model ! []
            Ok fetchedFriends ->
              let newFriends = Dict.fromList (List.map (\friend -> (friend.id, friend)) fetchedFriends)
              in
                { friends = newFriends, myself = myself } ! []
        GotError -> model ! []


view : Model -> Html Msg
view model =
    div [ Attrs.id "Root" ]
        [ viewMyself model.myself
        , div [ Attrs.class "TheFriendZone" ] (Dict.values model.friends |> List.map viewFriend)
        ]

viewMyself : Friend -> Html Msg
viewMyself myself =
  div [ Attrs.class "Myself"] [ viewFriend myself
         , colorUpdateForm myself.color
         ]
viewFriend : Friend -> Html msg
viewFriend { name, color } =
    div [ Attrs.style [ ("backgroundColor", color) ], Attrs.class "Friend" ] [ text name ]

colorUpdateForm : Friend.Color -> Html Msg
colorUpdateForm color =
    div [ Attrs.class "ColorSelect"]
        [ select
              [ onInput UpdateMyself ]
              (List.map
                   (\c -> colorOption c (c == color))
                   ["red", "green", "blue", "purple", "orange", "brown"])
        ]

colorOption : Friend.Color -> Bool -> Html msg
colorOption color isSelected =
    option [ Attrs.value color, Attrs.selected isSelected ] [ text color ]

-- Decoders
decodeFriendUpdate : JSDecode.Decoder Msg
decodeFriendUpdate =
  decode FriendUpdate
    |> required "id" JSDecode.int
    |> required "color" JSDecode.string

decodeWebsocketMessage : JSDecode.Decoder Msg
decodeWebsocketMessage =
  JSDecode.oneOf [
    JSDecode.field "FriendUpdate" decodeFriendUpdate
  ]

-- subscriptions
subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
  [ login Login
  , WebSocket.listen websocketAddress (\s -> (JSDecode.decodeString decodeWebsocketMessage s) |> Result.withDefault GotError)
  ]

port login : (AuthCredentials -> msg) -> Sub msg
