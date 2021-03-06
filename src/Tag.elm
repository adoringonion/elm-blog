module Tag exposing (tag)

import Element exposing (Element)


tag : String -> Element msg
tag tagName =
    Element.link [] { url = "/?tag=" ++ tagName, label = Element.el [] (Element.text ("#" ++ tagName)) }
