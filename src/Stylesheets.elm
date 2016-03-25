module Stylesheets where

import Css exposing (..)
import Css.Elements exposing (..)
import Css.File as CssFile
import Classes exposing (..)


port files : CssFile.CssFileStructure
port files =
  CssFile.toFileStructure
    [ ("main.css", CssFile.compile css) ]


css : Stylesheet
css =
  stylesheet
    [ body
      [ margin zero
      , height (pct 100)
      , width (pct 100)
      ]
    , html
      [ height (pct 100)
      ]
    , selector "juicy-ace-editor"
      [ width (pct 50)
      , height (pct 100)
      ]
    , (#) Container
      [ displayFlex
      , position relative
      , width (pct 100)
      , height (pct 100)
      ]
    , (.) Container
      [ displayFlex
      , position relative
      , width (pct 100)
      , height (pct 100)
      , flexDirection column
      ]
    , (.) Editors
      [ displayFlex
      , position relative
      , width (pct 100)
      , property "height" "calc(100% - 80px)"
      ]
    , (.) Button
      [ displayFlex
      , height (px 80)
      , property "justify-content" "space-around"
      , children
        [ button
          [ width (pct 100)
          , height (pct 100)
          , border zero
          , backgroundColor (hex "9B74DF")
          , color (hex "FFF")
          , fontSize (em 2)
          , property "cursor" "pointer"
          , property "transition" "opacity 0.3s"
          , property "outline" "0"
          , disabled
            [ opacity (float 0.3)
            ]
          ]
        ]
      ]
    ]
