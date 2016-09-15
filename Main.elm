module Main exposing (..)

import Html exposing (..)
import Html.App as Html
import Html.Attributes exposing (..)
import Html.Events exposing (onInput)
import Dict exposing (Dict)
import List

main : Program Never
main =
    Html.program
        { init = (init, Cmd.none)
        , view = view
        , update = update
        , subscriptions = subscriptions
        }


-- model

type alias Model =
    { friends : Dict Id Friend
    , myself : Friend
    }

type alias Friend =
    { name : String
    , id : Id
    , color : Color
    }

type alias Id = Int

type alias Color = String

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
    = FriendUpdate Id Color
    | UpdateMyself Color


update : Msg -> Model -> (Model, Cmd Msg)
update msg { friends, myself } =
    case msg of
        FriendUpdate id color ->
            { myself = myself
            , friends = Dict.update id (Maybe.map (\f -> { f | color = color })) friends
            } ! []
        UpdateMyself color ->
            { friends = friends
            , myself = { myself | color = color }
            } ! []

view : Model -> Html Msg
view model =
    div []
        ([ viewFriend model.myself
         , colorUpdateForm model.myself.color
         ]
             ++
             (Dict.values model.friends |> List.map viewFriend))

viewFriend : Friend -> Html msg
viewFriend { name, color } =
    div [ style [ ("backgroundColor", color) ] ] [ text name ]

colorUpdateForm : Color -> Html Msg
colorUpdateForm color =
    div []
        [ select
              [ onInput UpdateMyself ]
              (List.map
                   (\c -> colorOption c (c == color))
                   ["red", "green", "blue"])
        ]

colorOption : Color -> Bool -> Html msg
colorOption color isSelected =
    option [ value color, selected isSelected ] [ text color ]



-- subscriptions
subscriptions : Model -> Sub Msg
subscriptions model = Sub.none
