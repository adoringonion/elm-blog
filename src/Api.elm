module Api exposing (routes)

import ApiRoute
import Article
import DataSource exposing (DataSource)
import Html exposing (Html)
import Pages
import Route exposing (Route)
import Rss
import Time


routes :
    DataSource (List Route)
    -> (Html Never -> String)
    -> List (ApiRoute.ApiRoute ApiRoute.Response)
routes _ _ =
    [ rss
        { siteTagline = "ぶんぶんのブログです"
        , siteUrl = "https://adoringonion.com/"
        , title = "Bunlog"
        , builtAt = Pages.builtAt
        , indexPage = [ "/" ]
        }
        postsDataSource
    ]


postsDataSource : DataSource.DataSource (List Rss.Item)
postsDataSource =
    Article.allPosts
        |> DataSource.map
            (List.map
                (\article ->
                    { title = article.title
                    , description = article.description
                    , url = "blog/post/" ++ article.id
                    , categories = []
                    , author = "Fumihito Morita"
                    , pubDate = Rss.Date article.publishedAt
                    , content = Nothing
                    , contentEncoded = Nothing
                    , enclosure = Nothing
                    }
                )
            )


rss :
    { siteTagline : String
    , siteUrl : String
    , title : String
    , builtAt : Time.Posix
    , indexPage : List String
    }
    -> DataSource.DataSource (List Rss.Item)
    -> ApiRoute.ApiRoute ApiRoute.Response
rss options itemsRequest =
    ApiRoute.succeed
        (itemsRequest
            |> DataSource.map
                (\items ->
                    { body =
                        Rss.generate
                            { title = options.title
                            , description = options.siteTagline
                            , url = options.siteUrl ++ "/" ++ String.join "/" options.indexPage
                            , lastBuildTime = options.builtAt
                            , generator = Just "Bunlog"
                            , items = items
                            , siteUrl = options.siteUrl
                            }
                    }
                )
        )
        |> ApiRoute.literal "/feed.xml"
        |> ApiRoute.single
