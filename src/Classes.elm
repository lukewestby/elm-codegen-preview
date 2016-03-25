module Classes
  ( Classes(..)
  , class
  ) where

import Html exposing (Attribute)
import Html.CssHelpers as HtmlCss


type Classes
  = Container
  | Editors
  | Button


class : List Classes -> Attribute
class =
  HtmlCss.namespace "" |> .class
