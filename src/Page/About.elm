module Page.About exposing (Data, Model, Msg, page)

import Article exposing (..)
import DataSource exposing (DataSource)
import DataSource.File
import Date exposing (..)
import Element exposing (..)
import Head
import Head.Seo as Seo
import Markdown
import Page exposing (Page, StaticPayload)
import Pages.PageUrl exposing (PageUrl)
import Pages.Url
import Shared
import View exposing (View)
import Path


type alias Model =
    ()


type alias Msg =
    Never


type alias RouteParams =
    {}


page : Page RouteParams Data
page =
    Page.single
        { head = head
        , data = data
        }
        |> Page.buildNoState { view = view }


data : DataSource String
data =
    DataSource.File.rawFile "content/about.md"


head :
    StaticPayload Data RouteParams
    -> List Head.Tag
head _ =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = ""
        , image =
            { url = [ "images", "icon.jpeg" ] |> Path.join |> Pages.Url.fromPath
            , alt = "Bunlog logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "ぶんぶんについて"
        , locale = Nothing
        , title = "About | Bunlog"
        }
        |> Seo.profile { firstName = "Fumihito", lastName = "Morita", username = Just "adoring_onion" }


type alias Data =
    String


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view _ _ static =
    { title = "About | Bunlog"
    , body = [ aboutBody static.data ]
    }


aboutBody : String -> Element Msg
aboutBody body =
    Element.paragraph
        [ Element.width Element.fill
        , Element.paddingXY 100 40
        ]
        [ Element.html
            (Markdown.toHtml [] body)
        ]
