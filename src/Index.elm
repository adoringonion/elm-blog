module Index exposing (view)

import Date
import Element exposing (Element, centerX)
import Element.Border
import Element.Font
import Element.Region exposing (description)
import Metadata exposing (Metadata)
import Pages
import Pages.ImagePath exposing (ImagePath)
import Pages.PagePath as PagePath exposing (PagePath)
import Element


type alias PostEntry =
    ( PagePath Pages.PathKey, Metadata.ArticleMetadata )


view :
    List ( PagePath Pages.PathKey, Metadata )
    -> Element msg
view posts =
    Element.column [ Element.spacing 20 ]
        (posts
            |> List.filterMap
                (\( path, metadata ) ->
                    case metadata of
                        Metadata.Page meta ->
                            Nothing

                        Metadata.Article meta ->
                            if meta.draft then
                                Nothing

                            else
                                Just ( path, meta )

                        Metadata.BlogIndex ->
                            Nothing
                )
            |> List.sortWith postPublishDateDescending
            |> List.map postSummary
        )


postPublishDateDescending : PostEntry -> PostEntry -> Order
postPublishDateDescending ( _, metadata1 ) ( _, metadata2 ) =
    Date.compare metadata2.published metadata1.published


postSummary : PostEntry -> Element msg
postSummary ( postPath, post ) =
    articleIndex post
        |> linkToPost postPath


linkToPost : PagePath Pages.PathKey -> Element msg -> Element msg
linkToPost postPath content =
    Element.link [ Element.width Element.fill ]
        { url = PagePath.toString postPath, label = content }


title : String -> Element msg
title text =
    [ Element.text text ]
        |> Element.paragraph
            [ Element.Font.size 20
            , Element.Font.family [ Element.Font.typeface "Raleway" ]
            , Element.Font.semiBold
            ]


articleIndex : Metadata.ArticleMetadata -> Element msg
articleIndex metadata =
    Element.el
        [ Element.centerX
        , Element.width Element.fill
        , Element.padding 10
        , Element.spacing 10
        , Element.Border.width 1
        , Element.Border.color (Element.rgba255 0 0 0 0.1)
        , Element.Border.rounded 10
        ]
        (postPreview metadata)


postPreview : Metadata.ArticleMetadata -> Element msg
postPreview post =
    Element.row
        [ Element.width Element.fill ]
        [ Element.textColumn
            [ Element.centerX
            , Element.width (Element.fill |> Element.maximum 300)
            , Element.padding 10
            , Element.spacing 12
            , Element.Font.size 17
            ]
            [ title post.title
            , postPublishedDate post.published
            , post.description |> Element.text |> List.singleton |> Element.paragraph []
            ]
        , articleImageView post.image
        ]


postPublishedDate : Date.Date -> Element msg
postPublishedDate published =
    [ Element.text (published |> Date.format "yyyy-MM-dd") ]
        |> Element.paragraph [ Element.Font.size 14 ]


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.image [ Element.width (Element.fill |> Element.minimum 100 |> Element.maximum 300), Element.height (Element.shrink |> Element.maximum 100), Element.clip ]
        { src = Pages.ImagePath.toString articleImage
        , description = "Article cover photo"
        }
