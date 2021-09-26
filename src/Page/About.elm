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
import Path
import Shared
import View exposing (View)
import Css exposing (static)

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
head static =
    Seo.summary
        { canonicalUrlOverride = Nothing
        , siteName = "elm-pages"
        , image =
            { url = Pages.Url.external "TODO"
            , alt = "elm-pages logo"
            , dimensions = Nothing
            , mimeType = Nothing
            }
        , description = "TODO"
        , locale = Nothing
        , title = "TODO title" -- metadata.title -- TODO
        }
        |> Seo.website


type alias Data =
    String


view :
    Maybe PageUrl
    -> Shared.Model
    -> StaticPayload Data RouteParams
    -> View Msg
view maybeUrl sharedModel static =
    { title = "About"
    , body = [ aboutBody static.data ]
    }





aboutBody  : String -> Element Msg
aboutBody body =
    Element.paragraph
        [
         Element.width Element.fill
        , Element.paddingXY 100 40
        ]
        [ Element.html
            (Markdown.toHtml [] body)
        ]
