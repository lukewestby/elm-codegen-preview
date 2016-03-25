module Main where

import Task exposing (Task)
import Json.Encode as Encode
import Html exposing (Html, Attribute)
import Html.Attributes as HtmlAttr
import Html.Events as HtmlEv
import Effects exposing (Effects, Never)
import StartApp exposing (App)
import Http.Extra as Http
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


update : Action -> Model -> (Model, Effects Action)
update action model =
  case action of
    UpdateSourceCode newValue ->
      ( { model | sourceCode = newValue }
      , Effects.none
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
      , Effects.none
      )

    CompilationFailure ->
      ( { model
        | isProcessing = False
        , compilationResult = Nothing
        , compilationFailed = True
        }
      , Effects.none
      )


compileCode : String -> Effects Action
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
      |> Task.map (.data >> CompilationSuccess)
      |> (flip Task.onError) (always CompilationFailure >> Task.succeed)
      |> Effects.task


view : Signal.Address Action -> Model -> Html
view address model =
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
          , HtmlEv.on "change" HtmlEv.targetValue (UpdateSourceCode >> Signal.message address)
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
          [ HtmlEv.onClick address CompilationStart
          , HtmlAttr.disabled model.isProcessing
          ]
          [ Html.text compileButtonText ]
        ]
      ]


app : App Model
app =
  StartApp.start
    { update = update
    , view = view
    , init = (initialModel, Effects.none)
    , inputs = []
    }


port tasks : Signal (Task Never ())
port tasks =
  app.tasks


port model : Signal Model
port model =
  Signal.map (Debug.log "model") app.model


main : Signal Html
main =
  app.html
