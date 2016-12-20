port module Main exposing (..)

import Dict exposing (Dict)
import Html exposing (..)
import Html
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Http
import List

import Auth exposing (AuthCredentials)
import Friends
import Model.Friend as Friend exposing (Friend)

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


update : Msg -> Model -> (Model, Cmd Msg)
update msg ({ friends, myself } as model) =
    case msg of
        FriendUpdate id color ->
            { myself = myself
            , friends = Dict.update id (Maybe.map (\f -> { f | color = color })) friends
            } ! []
        UpdateMyself color ->
            { friends = friends
            , myself = { myself | color = color }
            } ! []
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

view : Model -> Html Msg
view model =
    div [ id "Root" ]
        [ viewMyself model.myself
        , div [ class "TheFriendZone" ] (Dict.values model.friends |> List.map viewFriend)
        ]

viewMyself : Friend -> Html Msg
viewMyself myself =
  div [ class "Myself"] [ viewFriend myself
         , colorUpdateForm myself.color
         ]
viewFriend : Friend -> Html msg
viewFriend { name, color } =
    div [ style [ ("backgroundColor", color) ], class "Friend" ] [ text name ]

colorUpdateForm : Friend.Color -> Html Msg
colorUpdateForm color =
    div [ class "ColorSelect"]
        [ select
              [ onInput UpdateMyself ]
              (List.map
                   (\c -> colorOption c (c == color))
                   ["red", "green", "blue", "purple", "orange", "brown"])
        ]

colorOption : Friend.Color -> Bool -> Html msg
colorOption color isSelected =
    option [ value color, selected isSelected ] [ text color ]



-- subscriptions
subscriptions : Model -> Sub Msg
subscriptions model = Sub.batch
  [ login Login
  ]

port login : (AuthCredentials -> msg) -> Sub msg
