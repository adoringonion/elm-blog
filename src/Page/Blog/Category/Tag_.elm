module Page.Blog.Category.Tag_ exposing (..)

import Article exposing (..)
import Css exposing (static)
import DataSource
import Date exposing (..)
import Element exposing (..)
import Element.Background exposing (..)
import Element.Font
import Head
import Head.Seo as Seo
import Page exposing (Page, StaticPayload)
import Page.Index
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
    { tag : String }


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
    Article.allTags
        |> DataSource.map (List.map (\tag -> { tag = tag.id }))


data : RouteParams -> DataSource.DataSource Data
data route =
    let
        entries =
            Article.allPosts
                |> DataSource.map
                    (\allPost ->
                        List.filter
                            (\post ->
                                List.member route.tag
                                    (List.map
                                        (\tag -> tag.id)
                                        post.tags
                                    )
                            )
                            allPost
                    )

        tagName =
            Article.allTags
                |> DataSource.map
                    (\allTags ->
                        List.filter (\tag -> tag.id == route.tag) allTags
                    )
                |> DataSource.map List.head
                |> DataSource.map (Maybe.map (\tag -> tag.name))
                |> DataSource.map (Maybe.withDefault "")
    in
    DataSource.map2 Data entries tagName


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
        , description = "タグ " ++ static.routeParams.tag ++ "がついた記事一覧"
        , locale = Nothing
        , title = "タグ " ++ static.routeParams.tag ++ "がついた記事一覧 | MyBlog" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    { entries : List Entry, tag : String }


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    { title = static.data.tag ++ " | Blog"
    , body = [ wrapper static.data.entries static.data.tag ]
    }


wrapper : List Entry -> String -> Element Msg
wrapper entries tag =
    Element.column
        [ Element.paddingXY 50 70
        , Element.width Element.fill
        , centerX
        , Element.spacing 40
        ]
        [ Element.el
            [ Element.width Element.fill
            , Element.Font.center
            , Element.Font.semiBold
            , Element.Font.size 36
            ]
            (Element.text ("#" ++ tag))
        , articleColumn entries
        ]


articleColumn : List Entry -> Element Msg
articleColumn entries =
    Element.column
        [ centerX, Element.width (Element.fill |> Element.maximum 600), Element.spacing 20 ]
        (List.map Page.Index.articleCard entries)
