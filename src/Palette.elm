module Palette exposing (blogHeading, color)

import Element exposing (Element)
import Element.Font as Font
import Element.Region


color :
    { primary : Element.Color
    , secondary : Element.Color
    }
color =
    { primary = Element.rgb255 107 169 227
    , secondary = Element.rgb255 29 27 65
    }


blogHeading : String -> Element msg
blogHeading title =
    Element.paragraph
        [ Font.bold
        , Font.family [ Font.typeface "Raleway" ]
        , Element.Region.heading 1
        , Font.size 36
        , Font.center
        ]
        [ Element.text title ]
