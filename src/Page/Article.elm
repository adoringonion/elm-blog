module Page.Article exposing (view)

import Date exposing (Date)
import Element exposing (Element)
import Element.Border
import Element.Font as Font
import Metadata exposing (ArticleMetadata)
import Pages
import Pages.ImagePath as ImagePath exposing (ImagePath)
import Palette


view : ArticleMetadata -> Element msg -> { title : String, body : List (Element msg) }
view metadata viewForPage =
    { title = metadata.title
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


tagsView : { a | tags : List String } -> Element msg
tagsView metadata =
    Element.row [ Element.spacing 10 ] (List.map tag metadata.tags)


tag : String -> Element msg
tag tagName =
    Element.link [] { url = "/tags/" ++ tagName, label = Element.el [] (Element.text tagName) }


articleImageView : ImagePath Pages.PathKey -> Element msg
articleImageView articleImage =
    Element.image [ Element.width Element.fill ]
        { src = ImagePath.toString articleImage
        , description = "Article cover photo"
        }
