module Classes exposing (Classes(..), class)

import Html exposing (Attribute)
import Html.CssHelpers as HtmlCss


type Classes
  = Container
  | Editors
  | Button


class : List Classes -> Attribute msg
class =
  HtmlCss.withNamespace "" |> .class
