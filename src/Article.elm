module Article exposing (AricleMetadata, Tag, allPosts, allTags, getPostBodyById, getMetadataById, summarize)

import DataSource
import DataSource.Http
import Date exposing (Date)
import OptimizedDecoder as Decode
import Pages.Secrets as Secrets
import Regex exposing (Regex)
import String.Extra exposing (ellipsis)


type alias AricleMetadata =
    { id : String
    , title : String
    , description : String
    , publishedAt : Date
    , revisedAt : Date
    , tags : List Tag
    }


type alias Tag =
    { id : String, name : String }


allPosts : DataSource.DataSource (List AricleMetadata)
allPosts =
    DataSource.Http.request
        (Secrets.succeed
            (\apiKey ->
                { url = "https://adoringonion.microcms.io/api/v1/blog?limit=1000"
                , method = "GET"
                , headers = [ ( "X-API-KEY", apiKey ) ]
                , body = DataSource.Http.emptyBody
                }
            )
            |> Secrets.with "API_KEY"
        )
        (contentsDecoder entryDecoder)

getMetadataById : String -> DataSource.DataSource AricleMetadata
getMetadataById id =
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

getPostBodyById : String -> DataSource.DataSource String
getPostBodyById id =
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
        (Decode.field "body" Decode.string)


allTags : DataSource.DataSource (List Tag)
allTags =
    DataSource.Http.request
        (Secrets.succeed
            (\apiKey ->
                { url = "https://adoringonion.microcms.io/api/v1/tags?limit=1000"
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


entryDecoder : Decode.Decoder AricleMetadata
entryDecoder =
    Decode.map6 AricleMetadata
        (Decode.field "id" Decode.string)
        (Decode.field "title" Decode.string)
        bodyDecoder
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

bodyDecoder : Decode.Decoder String
bodyDecoder =
    Decode.field "body" Decode.string
        |> Decode.andThen
            (\body ->
                summarize body |> Decode.succeed
            )


tagDecoder : Decode.Decoder Tag
tagDecoder =
    Decode.map2 Tag (Decode.field "id" Decode.string) (Decode.field "name" Decode.string)


summarize : String -> String
summarize body =
    body
        |> Regex.replace (regexFromString "#+ .+") (always "")
        |> Regex.replace (regexFromString "\\[") (always "")
        |> Regex.replace (regexFromString "\\]") (always "")
        |> Regex.replace (regexFromString "\\(http.+\\)") (always "")
        |> ellipsis 150


regexFromString : String -> Regex
regexFromString =
    Regex.fromString >> Maybe.withDefault Regex.never
