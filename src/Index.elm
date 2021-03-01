module Index exposing (view)

import Date
import Element exposing (Element)
import Element.Border
import Element.Font
import Element.Region exposing (description)
import Metadata exposing (Metadata)
import Pages
import Pages.ImagePath exposing (ImagePath)
import Pages.PagePath as PagePath exposing (PagePath)


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
            [ Element.Font.size 23
            , Element.Font.center
            , Element.Font.family [ Element.Font.typeface "Raleway" ]
            , Element.Font.semiBold
            ]


articleIndex : Metadata.ArticleMetadata -> Element msg
articleIndex metadata =
    Element.el
        [ Element.centerX
        , Element.width (Element.maximum 300 Element.fill)
        , Element.padding 20
        , Element.spacing 10
        , Element.Border.width 1
        , Element.Border.color (Element.rgba255 0 0 0 0.1)
        , Element.Border.rounded 10
        ]
        (postPreview metadata)


postPreview : Metadata.ArticleMetadata -> Element msg
postPreview post =
    Element.textColumn
        [ Element.centerX
        , Element.width Element.fill
        , Element.spacing 12
        , Element.Font.size 14
        ]
        [ title post.title
        , Element.row [ Element.spacing 10, Element.centerX ]
            [ Element.text (post.published |> Date.format "yyyy-MM-dd")
            ]
        , articleImageView post.image
        , post.description
            |> Element.text
            |> List.singleton
            |> Element.paragraph
                [ Element.Font.size 15
                , Element.Font.center
                , Element.Font.family [ Element.Font.typeface "Raleway" ]
                ]
        ]


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.row [ Element.centerX ]
        [ Element.image [ Element.width Element.fill, Element.height (Element.fill |> Element.maximum 200), Element.clip ]
            { src = Pages.ImagePath.toString articleImage
            , description = "Article cover photo"
            }
        ]
