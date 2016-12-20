module Friends exposing (..)

import Http
import Json.Decode as JSDecode

import Model.Friend as Friend exposing (Friend)

type FriendHttpMsg
  = ReceivedLoggedInUser (Result Http.Error Friend)
  | ReceivedFriendsForLoggedInUser (Result Http.Error (List Friend))

getUserWithId : Friend.Id -> Cmd FriendHttpMsg
getUserWithId userId =
  Http.send ReceivedLoggedInUser <|
    Http.get ("http://localhost:1234/user/" ++ (toString userId)) Friend.decodeFriend


getFriendsForUserWithId : Friend.Id -> Cmd FriendHttpMsg
getFriendsForUserWithId userId =
  Http.send ReceivedFriendsForLoggedInUser <|
    Http.get
      ("http://localhost:1234/friends?loggedInUserId=" ++ (toString userId))
      (JSDecode.list Friend.decodeFriend)
