module Page.Blog.Post.Slug_ exposing (..)

import Article exposing (..)
import DataSource
import Date exposing (..)
import Element exposing (..)
import Element.Background exposing (..)
import Element.Font as Font
import Head
import Head.Seo as Seo
import Html.Attributes exposing (class)
import Markdown
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared exposing (Msg)
import View exposing (View)
import Path


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    { slug : String }


page : Page RouteParams Data
page =
    Page.prerender
        { head = head
        , data = data
        , routes = routes
        }
        |> Page.buildNoState { view = view }


routes : DataSource.DataSource (List RouteParams)
routes =
    Article.allPosts
        |> DataSource.map
            (List.map
                (\post ->
                    { slug = post.id }
                )
            )


data : RouteParams -> DataSource.DataSource Data
data route =
    Article.getPostById route.slug


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = ""
        , image =
            { url = [ "images", "icon.jpeg" ] |> Path.join |> Pages.Url.fromPath
            , alt = "Bunlog logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = summarize static.data
        , locale = Nothing
        , title = static.data.title ++ " | Bunlog"
        }
        |> Seo.article
            { expirationTime = Nothing
            , modifiedTime = Just (Date.format "yyy-MM-dd" static.data.revisedAt)
            , publishedTime = Just (Date.format "yyy-MM-dd" static.data.publishedAt)
            , section = Nothing
            , tags = List.map (\tag -> tag.name) static.data.tags
            }


type alias Data =
    Entry


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    { title = static.data.title ++ " | MyBlog"
    , body = [ viewPost static.data ]
    }


viewPost : Entry -> Element Msg
viewPost entry =
    column
        [ Element.width (Element.fill |> Element.maximum 1000)
        , Element.centerX
        , Element.paddingXY 0 50
        , Element.spacing 20
        ]
        [ viewTitle entry.title
        , dateAndTags entry.publishedAt entry.tags
        , column
            [ Element.centerX
            , Element.paddingXY 30 20
            ]
            [ postBody entry.body ]
        ]


dateAndTags : Date -> List Tag -> Element Msg
dateAndTags published tags =
    Element.column
        [ Element.width Element.fill
        , Element.paddingXY 60 0
        , Element.spacing 10
        ]
        [ publishedDateView published
        , viewTags tags
        ]


postBody : String -> Element Msg
postBody body =
    Element.paragraph
        [ Element.width Element.fill
        ]
        [ Element.html
            (Markdown.toHtml [ class "postBody" ] body)
        ]


viewTitle : String -> Element Msg
viewTitle title =
    Element.paragraph
        [ Font.center
        , Font.size 40
        , Font.bold
        , Element.width Element.fill
        ]
        [ Element.text title
        ]


publishedDateView : Date -> Element msg
publishedDateView date =
    Element.row
        [ Font.size 15
        ]
        [ text (Date.format "yyy-MM-dd" date) ]


viewTags : List Tag -> Element msg
viewTags tags =
    Element.row
        [ Element.padding 3
        , Element.spacing 8
        ]
        (List.map
            (\tag ->
                Element.link
                    [ Element.padding 3
                    ]
                    { url = "/blog/category/" ++ tag.id, label = text ("#" ++ tag.name) }
            )
            tags
        )
