module Layout exposing (view)

import DocumentSvg
import Element exposing (Element)
import Element.Background
import Element.Border
import Element.Font as Font
import Element.Region
import Html exposing (Html)
import Metadata exposing (Metadata)
import Pages
import Pages.Directory as Directory exposing (Directory)
import Pages.ImagePath as ImagePath
import Pages.PagePath as PagePath exposing (PagePath)
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
                    [ Element.width (Element.fill |> Element.minimum 530) ]
                    [ header page.path
                    , Element.column
                        [ Element.padding 30
                        , Element.spacing 40
                        , Element.Region.mainContent
                        , Element.width (Element.fill |> Element.maximum 800)
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
                    [ Element.width (Element.fill |> Element.minimum 530) ]
                    [ header page.path
                    , Element.column
                        [ Element.padding 30
                        , Element.spacing 40
                        , Element.Region.mainContent
                        , Element.width (Element.fill |> Element.maximum 800)
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


header : PagePath Pages.PathKey -> Element msg
header currentPath =
    Element.column [ Element.width Element.fill ]
        [ Element.row
            [ Element.paddingXY 25 15
            , Element.spaceEvenly
            , Element.width Element.fill
            , Element.Region.navigation
            , Element.Border.widthEach { bottom = 1, left = 0, right = 0, top = 0 }
            , Element.Border.color (Element.rgba255 40 80 40 0.4)
            ]
            [ Element.link []
                { url = "/"
                , label =
                    Element.row [ Font.size 30, Element.spacing 16 ]
                        [ Element.text "Bunlog"
                        ]
                }
            , Element.row [ Element.spacing 15 ]
                [ githubRepoLink
                , Element.link [] { url = "about", label = Element.text "About" }
                ]
            ]
        ]


githubRepoLink : Element msg
githubRepoLink =
    Element.newTabLink []
        { url = "https://github.com/adoringonion"
        , label =
            Element.image
                [ Element.width (Element.px 22)
                , Font.color Palette.color.primary
                ]
                { src = ImagePath.toString Pages.images.github, description = "Github repo" }
        }
