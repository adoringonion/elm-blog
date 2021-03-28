module Tag exposing (tag)

import Element exposing (Element, padding, rgb)
import Element.Border
import MyColor


tag : String -> Element msg
tag tagName =
    Element.link
        [ padding 2
        , Element.Border.color MyColor.primary
        , Element.Border.solid
        , Element.Border.widthEach { bottom = 3, right = 0, left = 0, top = 0 }
        ]
        { url = "/?tag=" ++ tagName, label = Element.text tagName }
