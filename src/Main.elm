module Main exposing (main)

import Task exposing (Task)
import Json.Encode as Encode
import Json.Decode as Decode
import Html exposing (Html, Attribute)
import Html.Attributes as HtmlAttr
import Html.Events as HtmlEv
import Html.App
import HttpBuilder as Http
import Classes exposing (Classes(..))


type alias Model =
  { isProcessing : Bool
  , compilationFailed : Bool
  , compilationResult : Maybe String
  , sourceCode : String
  }


defaultSourceCode : String
defaultSourceCode =
  """module Main where

import Graphics.Element exposing (Element, show)


main : Element
main =
  show "Hello world!"
  """


initialModel : Model
initialModel =
  Model
    False
    False
    Nothing
    defaultSourceCode


type Action
  = UpdateSourceCode String
  | CompilationStart
  | CompilationSuccess String
  | CompilationFailure


update : Action -> Model -> (Model, Cmd Action)
update action model =
  case action of
    UpdateSourceCode newValue ->
      ( { model | sourceCode = newValue }
      , Cmd.none
      )

    CompilationStart ->
      ( { model
        | isProcessing = True
        , compilationFailed = False
        }
      , compileCode model.sourceCode
      )

    CompilationSuccess result ->
      ( { model
        | isProcessing = False
        , compilationResult = Just result
        }
      , Cmd.none
      )

    CompilationFailure ->
      ( { model
        | isProcessing = False
        , compilationResult = Nothing
        , compilationFailed = True
        }
      , Cmd.none
      )


compileCode : String -> Cmd Action
compileCode source =
  let
    payload =
      Encode.object
        [ ("runtime", Encode.bool False)
        , ("source", Encode.string source)
        ]
  in
    Http.post "https://ecaas.herokuapp.com/compile"
      |> Http.withHeader "Content-Type" "application/json"
      |> Http.withJsonBody payload
      |> Http.send Http.stringReader Http.stringReader
      |> Task.map .data
      |> Task.perform (always CompilationFailure) CompilationSuccess


view : Model -> Html Action
view model =
  let
    compileButtonText =
      if model.isProcessing then
        "Compiling..."
      else if model.compilationFailed then
        "The compilation server failed \x1f615"
      else
        "Compile"
  in
    Html.div
      [ Classes.class [ Container ] ]
      [ Html.div
        [ Classes.class [ Editors ] ]
        [ Html.node "juicy-ace-editor"
          [ HtmlAttr.attribute "mode" "ace/mode/elm"
          , HtmlAttr.attribute "theme" "ace/theme/monokai"
          , HtmlAttr.attribute "value" model.sourceCode
          , HtmlAttr.attribute "softtabs" "true"
          , HtmlAttr.attribute "tabsize" "2"
          , HtmlEv.on "change" (Decode.at ["target", "value"] Decode.string |> Decode.map UpdateSourceCode)
          ]
          [ Html.text defaultSourceCode ]
        , Html.node "juicy-ace-editor"
          [ HtmlAttr.attribute "mode" "ace/mode/javascript"
          , HtmlAttr.attribute "theme" "ace/theme/monokai"
          , HtmlAttr.attribute "value" (model.compilationResult |> Maybe.withDefault "")
          , HtmlAttr.attribute "readonly" "true"
          ]
          [ Html.text (model.compilationResult |> Maybe.withDefault "") ]
        ]
      , Html.div
        [ Classes.class [ Button ] ]
        [ Html.button
          [ HtmlEv.onClick CompilationStart
          , HtmlAttr.disabled model.isProcessing
          ]
          [ Html.text compileButtonText ]
        ]
      ]


main : Program Never
main =
    Html.App.program
    { update = update
    , view = view
    , init = (initialModel, Cmd.none)
    , subscriptions = (always Sub.none)
    }


{-
port model : Signal Model
port model =
  Signal.map (Debug.log "model") app.model
-}
