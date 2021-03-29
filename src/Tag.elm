module Tag exposing (tag, tagLink)

import Element exposing (Element, padding)
import Element.Background
import Element.Border
import Element.Font
import Palette


tag : String -> Element msg
tag tagName =
    Element.el
        [ padding 2
        , Element.Border.color Palette.color.primary
        , Element.Border.solid
        , Element.padding 5
        , Element.Border.rounded 4
        , Element.Border.width 1
        ]
        (Element.el
            [ Element.Font.color Palette.color.primary
            ]
            (Element.text tagName)
        )


tagLink : String -> Element msg
tagLink tagName =
    Element.link
        [ Element.Border.color Palette.color.primary
        , Element.Border.solid
        , Element.Border.width 1
        , Element.Border.rounded 3
        , Element.padding 5
        ]
        { url = "/?tag=" ++ tagName
        , label =
            Element.el
                [ Element.Font.color Palette.color.primary
                ]
                (Element.text tagName)
        }
