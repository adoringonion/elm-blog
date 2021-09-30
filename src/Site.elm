module Site exposing (config)

import DataSource
import Head
import LanguageTag
import LanguageTag.Language
import MimeType
import Pages.Manifest as Manifest
import Pages.Url
import Path
import Route
import SiteConfig exposing (SiteConfig)


type alias Data =
    ()


config : SiteConfig Data
config =
    { data = data
    , canonicalUrl = "https://adoringonion.com/"
    , manifest = manifest
    , head = head
    }


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


head : Data -> List Head.Tag
head _ =
    [ language
    , Head.rssLink "/feed.xml"
    , Head.icon [ ( 32, 32 ) ] MimeType.Jpeg ([ "images", "icon.jpeg" ] |> Path.join |> Pages.Url.fromPath)
    , Head.icon [ ( 16, 16 ) ] MimeType.Jpeg ([ "images", "icon.jpeg" ] |> Path.join |> Pages.Url.fromPath)
    ]


manifest : Data -> Manifest.Config
manifest _ =
    Manifest.init
        { name = "Bunlog"
        , description = "ぶんぶんのブログです"
        , startUrl = Route.Index |> Route.toPath
        , icons = []
        }


language : Head.Tag
language =
    LanguageTag.Language.ja
        |> LanguageTag.build LanguageTag.emptySubtags
        |> Head.rootLanguage
