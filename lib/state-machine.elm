port module StateMachine exposing (..)

import Char exposing (KeyCode)
import Html as Html exposing (..)
import Html.Events as Events exposing (..)
import Json.Decode as Json
import List exposing (any)
import String exposing (..)


main : Program Never Model Msg
main =
    Platform.program
        { init = init
        , update = update
        , subscriptions = subscriptions
        }


subscriptions : Model -> Sub Msg
subscriptions model =
    Sub.batch
        [ labels LoadLabels
        , key KeyEntered
        , reset (Basics.always Reset)
        , exit (Basics.always Exit)
        ]


type alias Labels =
    List String



-- Outbound


port activeChanged : Bool -> Cmd msg


port statusChanged : String -> Cmd msg


port validKeyEntered : String -> Cmd msg


port labelJumped : String -> Cmd msg



-- Inbound


port labels : (Labels -> msg) -> Sub msg


port key : (Int -> msg) -> Sub msg


port reset : (() -> msg) -> Sub msg


port exit : (() -> msg) -> Sub msg


type Msg
    = LoadLabels Labels
    | Reset
    | KeyEntered Int
    | Exit


type alias Model =
    { active : Bool
    , keysEntered : String
    , lastJumped : String
    , labels : Labels
    , status : String
    }


init : ( Model, Cmd Msg )
init =
    ( { active = False
      , keysEntered = ""
      , lastJumped = ""
      , labels = []
      , status = ""
      }
    , initCmds
    )


initCmds : Cmd Msg
initCmds =
    Cmd.none


onKeyPress : (Int -> msg) -> Attribute msg
onKeyPress tagger =
    on "keypress" (Json.map tagger keyCode)


clearStatus : Model -> Model
clearStatus model =
    { model | status = "" }


resetStatus : Model -> Model
resetStatus model =
    if model.active then
        { model | status = "<div id='status-bar-jumpy'>Jumpy: <span class='status'>Jump Mode!</span></div>" }
    else
        model


resetKeys : Model -> Model
resetKeys model =
    { model | keysEntered = "" }


turnOff : Model -> Model
turnOff model =
    { model | active = False }
        |> resetKeys
        |> clearStatus


setNoMatchStatus : Model -> Model
setNoMatchStatus model =
    { model | status = "<div id='status-bar-jumpy' class='no-match'>Jumpy: <span>No Match! 😞</span></div>" }


addKeyToStatus : String -> Model -> Model
addKeyToStatus keyEntered model =
    { model | status = "<div id='status-bar-jumpy'>Jumpy: <span class='status'>" ++ keyEntered ++ "</span></div>" }


modelAndStatus : Model -> ( Model, Cmd Msg )
modelAndStatus model =
    model
        ! [ activeChanged model.active
          , statusChanged model.status
          , validKeyEntered model.keysEntered
          ]


modelAndJumped : Model -> ( Model, Cmd Msg )
modelAndJumped model =
    model
        ! [ activeChanged model.active
          , statusChanged model.status
          , labelJumped model.lastJumped
          ]


turnOn : Model -> Model
turnOn model =
    { model | active = True }
        |> resetStatus


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        KeyEntered keyCode ->
            let
                keyEntered =
                    keyCode |> Char.fromCode |> String.fromChar

                newKeysEntered =
                    model.keysEntered ++ keyEntered

                keysEnteredMatch =
                    model.labels
                        |> List.any (\label -> startsWith newKeysEntered label)
            in
            if model.active then
                if not keysEnteredMatch then
                    model
                        |> setNoMatchStatus
                        |> modelAndStatus
                else if length model.keysEntered == 0 then
                    -- FIRST LETTER ----------
                    { model | keysEntered = newKeysEntered }
                        |> addKeyToStatus keyEntered
                        |> modelAndStatus
                else if length model.keysEntered == 1 then
                    -- SECOND LETTER ----------
                    { model | lastJumped = newKeysEntered }
                        |> turnOff
                        |> modelAndJumped
                else
                    model ! []
            else
                model ! []

        Reset ->
            if model.active then
                model
                    |> resetKeys
                    |> resetStatus
                    |> modelAndStatus
            else
                model ! []

        LoadLabels labels ->
            { model | labels = labels }
                |> turnOn
                |> modelAndStatus

        Exit ->
            model
                |> turnOff
                |> modelAndStatus
