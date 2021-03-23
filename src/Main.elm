module Main exposing (main)

import Color
import Date
import Element exposing (Attr, Element)
import Element.Font as Font
import Getto.Url.Query.Decode as Getto
import Head
import Head.Seo as Seo
import Html exposing (Html, p)
import Index
import Json.Decode
import Layout
import Markdown exposing (Options)
import Metadata exposing (Metadata)
import Page.Article
import Pages exposing (images, pages)
import Pages.Manifest as Manifest
import Pages.Manifest.Category
import Pages.PagePath exposing (PagePath)
import Pages.Platform
import Pages.StaticHttp as StaticHttp
import Svg exposing (metadata)


manifest : Manifest.Config Pages.PathKey
manifest =
    { backgroundColor = Just Color.white
    , categories = [ Pages.Manifest.Category.education ]
    , displayMode = Manifest.Standalone
    , orientation = Manifest.Portrait
    , description = "elm-pages-starter - A statically typed site generator."
    , iarcRatingId = Nothing
    , name = "elm-pages-starter"
    , themeColor = Just Color.black
    , startUrl = pages.index
    , shortName = Just "elm-pages-starter"
    , sourceIcon = images.icon
    , icons = []
    }


type alias Rendered =
    Element Msg


type alias Query =
    { tag : Maybe String }



-- the intellij-elm plugin doesn't support type aliases for Programs so we need to use this line
-- main : Platform.Program Pages.Platform.Flags (Pages.Platform.Model Model Msg Metadata Rendered) (Pages.Platform.Msg Msg Metadata Rendered)


main : Pages.Platform.Program Model Msg Metadata Rendered Pages.PathKey
main =
    Pages.Platform.init
        { init = \_ -> init
        , view = view
        , update = update
        , subscriptions = subscriptions
        , documents = [ markdownDocument ]
        , manifest = manifest
        , canonicalSiteUrl = canonicalSiteUrl
        , onPageChange = Just onPageChange
        , internals = Pages.internals
        }
        |> Pages.Platform.withFileGenerator generateFiles
        |> Pages.Platform.toProgram


generateFiles :
    List
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        , body : String
        }
    ->
        StaticHttp.Request
            (List
                (Result String
                    { path : List String
                    , content : String
                    }
                )
            )
generateFiles siteMetadata =
    StaticHttp.succeed
        []


markdownDocument : { extension : String, metadata : Json.Decode.Decoder Metadata, body : String -> Result error (Element msg) }
markdownDocument =
    { extension = "md"
    , metadata = Metadata.decoder
    , body =
        \markdownBody ->
            Markdown.toHtmlWith myOptions [] markdownBody
                |> Element.html
                |> List.singleton
                |> Element.paragraph [ Element.width (Element.fill |> Element.maximum 800) ]
                |> Ok
    }


myOptions : Options
myOptions =
    { githubFlavored = Just { tables = True, breaks = False }
    , defaultHighlighting = Nothing
    , sanitize = False
    , smartypants = False
    }


type alias Model =
    Query


init : ( Model, Cmd Msg )
init =
    ( { tag = Nothing }, Cmd.none )


type Msg
    = HasQuery Query
    | NoMsg


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HasQuery query ->
            ( query, Cmd.none )

        NoMsg ->
            ( { tag = Nothing }, Cmd.none )



--subscriptions : Model -> Sub Msg


subscriptions _ _ _ =
    Sub.none


onPageChange : { path : PagePath Pages.PathKey, query : Maybe String, fragment : Maybe String, metadata : Metadata } -> Msg
onPageChange page =
    case page.query of
        Just query ->
            decodeQuery query

        Nothing ->
            NoMsg


decodeQuery : String -> Msg
decodeQuery query =
    let
        tag =
            query |> Getto.split |> Getto.entryAt [ "tag" ] Getto.string
    in
    HasQuery { tag = tag }


view :
    List ( PagePath Pages.PathKey, Metadata )
    ->
        { path : PagePath Pages.PathKey
        , frontmatter : Metadata
        }
    ->
        StaticHttp.Request
            { view : Model -> Rendered -> { title : String, body : Html Msg }
            , head : List (Head.Tag Pages.PathKey)
            }
view siteMetadata page =
    StaticHttp.succeed
        { view =
            \model viewForPage ->
                Layout.view (pageView model siteMetadata page viewForPage) page
        , head = head page.frontmatter
        }


pageView :
    Model
    -> List ( PagePath Pages.PathKey, Metadata )
    -> { path : PagePath Pages.PathKey, frontmatter : Metadata }
    -> Rendered
    -> { title : String, body : List (Element Msg) }
pageView model siteMetadata page viewForPage =
    case page.frontmatter of
        Metadata.Page metadata ->
            { title = metadata.title
            , body =
                [ viewForPage
                ]

            --        |> Element.textColumn
            --            [ Element.width Element.fill
            --            ]
            }

        Metadata.Article metadata ->
            Page.Article.view metadata viewForPage

        Metadata.BlogIndex ->
            case model.tag of
                Just tag ->
                    { title = addTitle <| Just (tag ++ "のタグが付いた記事")
                    , body =
                        [ Element.column [ Element.padding 20, Element.centerX ] [ Index.view siteMetadata (Just tag) ]
                        ]
                    }

                Nothing ->
                    { title = addTitle Nothing
                    , body =
                        [ Element.column [ Element.padding 20, Element.centerX ] [ Index.view siteMetadata Nothing ]
                        ]
                    }


commonHeadTags : List (Head.Tag Pages.PathKey)
commonHeadTags =
    [ Head.rssLink "/blog/feed.xml"
    , Head.sitemapLink "/sitemap.xml"
    ]



{- Read more about the metadata specs:

   <https://developer.twitter.com/en/docs/tweets/optimize-with-cards/overview/abouts-cards>
   <https://htmlhead.dev>
   <https://html.spec.whatwg.org/multipage/semantics.html#standard-metadata-names>
   <https://ogp.me/>
-}


head : Metadata -> List (Head.Tag Pages.PathKey)
head metadata =
    commonHeadTags
        ++ (case metadata of
                Metadata.Page meta ->
                    Seo.summary
                        { canonicalUrlOverride = Nothing
                        , siteName = "ぶんログ"
                        , image =
                            { url = images.icon
                            , alt = "ぶんログ"
                            , dimensions = Nothing
                            , mimeType = Nothing
                            }
                        , description = siteTagline
                        , locale = Nothing
                        , title = meta.title
                        }
                        |> Seo.website

                Metadata.Article meta ->
                    Seo.summary
                        { canonicalUrlOverride = Nothing
                        , siteName = addTitle Nothing
                        , image =
                            { url = images.icon
                            , alt = meta.description
                            , dimensions = Nothing
                            , mimeType = Nothing
                            }
                        , description = meta.description
                        , locale = Nothing
                        , title = addTitle (Just meta.title)
                        }
                        |> Seo.article
                            { tags = []
                            , section = Nothing
                            , publishedTime = Just (Date.toIsoString meta.published)
                            , modifiedTime = Nothing
                            , expirationTime = Nothing
                            }

                Metadata.BlogIndex ->
                    Seo.summary
                        { canonicalUrlOverride = Nothing
                        , siteName = addTitle Nothing
                        , image =
                            { url = images.icon
                            , alt = "ぶんログ"
                            , dimensions = Nothing
                            , mimeType = Nothing
                            }
                        , description = siteTagline
                        , locale = Nothing
                        , title = addTitle Nothing
                        }
                        |> Seo.website
           )


canonicalSiteUrl : String
canonicalSiteUrl =
    "https://blog.adoring-onion.dev/"


siteTagline : String
siteTagline =
    "ぶんぶんのブログ"


addTitle : Maybe String -> String
addTitle pageTitle =
    case pageTitle of
        Just title ->
            "Bunlog | " ++ title

        Nothing ->
            "Bunlog"
