module Article exposing (Entry, Tag, allPosts, allTags, getPostById, summarize)

import DataSource
import DataSource.Http
import Date exposing (Date)
import OptimizedDecoder as Decode
import Pages.Secrets as Secrets
import Regex exposing (Regex)
import String.Extra exposing (ellipsis)


type alias Entry =
    { id : String
    , title : String
    , body : String
    , publishedAt : Date
    , revisedAt : Date
    , tags : List Tag
    }


type alias Tag =
    { id : String, name : String }


allPosts : DataSource.DataSource (List Entry)
allPosts =
    DataSource.Http.request
        (Secrets.succeed
            (\apiKey ->
                { url = "https://adoringonion.microcms.io/api/v1/blog"
                , method = "GET"
                , headers = [ ( "X-API-KEY", apiKey ) ]
                , body = DataSource.Http.emptyBody
                }
            )
            |> Secrets.with "API_KEY"
        )
        (contentsDecoder entryDecoder)


getPostById : String -> DataSource.DataSource Entry
getPostById id =
    DataSource.Http.request
        (Secrets.succeed
            (\apiKey ->
                { url = "https://adoringonion.microcms.io/api/v1/blog/" ++ id
                , method = "GET"
                , headers = [ ( "X-API-KEY", apiKey ) ]
                , body = DataSource.Http.emptyBody
                }
            )
            |> Secrets.with "API_KEY"
        )
        entryDecoder


allTags : DataSource.DataSource (List Tag)
allTags =
    DataSource.Http.request
        (Secrets.succeed
            (\apiKey ->
                { url = "https://adoringonion.microcms.io/api/v1/tags"
                , method = "GET"
                , headers = [ ( "X-API-KEY", apiKey ) ]
                , body = DataSource.Http.emptyBody
                }
            )
            |> Secrets.with "API_KEY"
        )
        (contentsDecoder tagDecoder)


contentsDecoder : Decode.Decoder a -> Decode.Decoder (List a)
contentsDecoder decoder =
    Decode.field "contents" <|
        Decode.list decoder


entryDecoder : Decode.Decoder Entry
entryDecoder =
    Decode.map6 Entry
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        (Decode.field "body" Decode.string)
        (Decode.field "publishedAt" dateDecoder)
        (Decode.field "revisedAt" dateDecoder)
        (Decode.field "tags" <| Decode.list tagDecoder)


dateDecoder : Decode.Decoder Date
dateDecoder =
    Decode.string
        |> Decode.andThen
            (\isoString ->
                String.slice 0 10 isoString
                    |> Date.fromIsoString
                    |> Decode.fromResult
            )


tagDecoder : Decode.Decoder Tag
tagDecoder =
    Decode.map2 Tag (Decode.field "id" Decode.string) (Decode.field "name" Decode.string)


summarize : Entry -> String
summarize entry =
    entry.body
        |> Regex.replace (regexFromString "#+ .+") (always "")
        |> Regex.replace (regexFromString "\\[") (always "")
        |> Regex.replace (regexFromString "\\]") (always "")
        |> Regex.replace (regexFromString "(http.+)") (always "")
        |> ellipsis 150


regexFromString : String -> Regex
regexFromString =
    Regex.fromString >> Maybe.withDefault Regex.never
