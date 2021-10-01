module Shared exposing (Data, Model, Msg(..), SharedMsg(..), template)

import Browser.Navigation
import DataSource
import Element exposing (Element, column, layout, link, row, text)
import Element.Background exposing (..)
import Element.Border
import Element.Font as Font
import Element.Region exposing (navigation)
import Html exposing (Html)
import List.Extra
import Pages.Flags
import Pages.PageUrl exposing (PageUrl)
import Path exposing (Path)
import Ports
import Route exposing (Route)
import SharedTemplate exposing (SharedTemplate)
import View exposing (View)


template : SharedTemplate Msg Model Data msg
template =
    { init = init
    , update = update
    , view = view
    , data = data
    , subscriptions = subscriptions
    , onPageChange = Just OnPageChange
    }


type Msg
    = OnPageChange
        { path : Path
        , query : Maybe String
        , fragment : Maybe String
        }
    | SharedMsg SharedMsg


type alias Data =
    ()


type SharedMsg
    = NoOp


type alias Model =
    { showMobileMenu : Bool
    }


init :
    Maybe Browser.Navigation.Key
    -> Pages.Flags.Flags
    ->
        Maybe
            { path :
                { path : Path
                , query : Maybe String
                , fragment : Maybe String
                }
            , metadata : route
            , pageUrl : Maybe PageUrl
            }
    -> ( Model, Cmd Msg )
init _ _ _  =
    ( { showMobileMenu = False }
    , Cmd.none
    )


update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        OnPageChange page ->
            let
                lastSegment =
                    Path.toSegments page.path |> List.Extra.last |> Maybe.withDefault ""
            in
            ( model, Ports.loadDisqus lastSegment )

        SharedMsg _ ->
            ( model, Cmd.none )


subscriptions : Path -> Model -> Sub Msg
subscriptions _ _ =
    Sub.none


data : DataSource.DataSource Data
data =
    DataSource.succeed ()


view :
    Data
    ->
        { path : Path
        , route : Maybe Route
        }
    -> Model
    -> (Msg -> msg)
    -> View msg
    -> { body : Html msg, title : String }
view _ _ _ _ pageView =
    { body =
        layout
            [ Element.width (Element.fill |> Element.minimum 700)
            ]
            (column
                [ Element.width Element.fill ]
                (header :: pageView.body)
            )
    , title = pageView.title
    }


header : Element msg
header =
    Element.row
        [ Element.width Element.fill
        , Element.height (Element.px 60)
        , Element.spaceEvenly
        , Element.paddingXY 30 10
        , Element.Border.shadow { blur = 5, size = 1, offset = ( 0, 0 ), color = Element.rgba 0 0 0 0.3 }
        ]
        [ Element.link
            [ Font.bold
            , Font.size 30
            ]
            { url = "/", label = text "Bunlog" }
        , menu
        ]


menu : Element msg
menu =
    row
        [ navigation
        , Element.spacing 40
        ]
        [ link [] { url = "/", label = text "Posts" }
        , link [] { url = "/about", label = text "About" }
        ]
