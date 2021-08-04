module Layout exposing (view)

import Element exposing (Element)
import Element.Border
import Element.Font as Font
import Element.Region
import Html exposing (Html)
import Metadata exposing (Metadata)
import Pages
import Pages.ImagePath as ImagePath
import Pages.PagePath exposing (PagePath)
import Palette


view :
    { title : String, body : List (Element msg) }
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    -> { title : String, body : Html msg }
view document page =
    { title = document.title
    , body =
        case page.frontmatter of
            Metadata.BlogIndex ->
                Element.column
                    [ Element.width (Element.fill |> Element.minimum 400) ]
                    [ header page.path
                    , Element.column
                        [ Element.padding 23
                        , Element.spacing 40
                        , Element.Region.mainContent
                        , Element.width (Element.fill |> Element.maximum 700)
                        , Element.centerX
                        ]
                        document.body
                    ]
                    |> Element.layout
                        [ Element.width Element.fill
                        , Font.size 20
                        , Font.family [ Font.typeface "Roboto" ]
                        , Font.color (Element.rgba255 0 0 0 0.8)
                        ]

            _ ->
                Element.column
                    [ Element.width (Element.fill |> Element.minimum 400) ]
                    [ header page.path
                    , Element.column
                        [ Element.padding 30
                        , Element.spacing 40
                        , Element.Region.mainContent
                        , Element.width (Element.fill |> Element.maximum 700 |> Element.minimum 400)
                        , Element.centerX
                        ]
                        document.body
                    ]
                    |> Element.layout
                        [ Element.width Element.fill
                        , Font.size 20
                        , Font.family [ Font.typeface "Roboto" ]
                        , Font.color (Element.rgba255 0 0 0 0.8)
                        ]
    }

