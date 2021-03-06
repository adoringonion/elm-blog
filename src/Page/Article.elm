module Page.Article exposing (view)

import Date exposing (Date)
import Element exposing (Element)
import Element.Font as Font
import Metadata exposing (ArticleMetadata)
import Pages
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Palette
import Tag


view : ArticleMetadata -> Element msg -> { title : String, body : List (Element msg) }
view metadata viewForPage =
    { title = addTitle (Just metadata.title)
    , body =
        [ publishedDateView metadata |> Element.el [ Font.size 16, Font.color (Element.rgba255 0 0 0 0.6) ]
        , Palette.blogHeading metadata.title
        , tagsView metadata
        , articleImageView metadata.image
        , viewForPage
        ]
    }


publishedDateView : { a | published : Date } -> Element msg
publishedDateView metadata =
    Element.text
        (metadata.published
            |> Date.format "yyyy-MM-dd"
        )


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.image [ Element.width Element.fill ]
        { src = ImagePath.toString articleImage
        , description = "Article cover photo"
        }


tagsView : { a | tags : List String } -> Element msg
tagsView metadata =
    Element.row [ Element.spacing 10 ] (List.map Tag.tag metadata.tags)


addTitle : Maybe String -> String
addTitle pageTitle =
    case pageTitle of
        Just title ->
            "Bunlog | " ++ title

        Nothing ->
            "Bunlog"
