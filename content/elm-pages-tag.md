---
type: blog
title: elm-pagesにタグ機能をつける
published: "2021-03-23"
description: ""
tags: ["Elm", "elm-pages"]
image: "none"
---

## はじめに

[前回](./blog-reneal)書いたように elm-pages でブログを作り直したんですが、Gatsby みたいにいっぱいプラグインがあるわけじゃないので、色んな機能を自分で作っていくことになります。初期テンプレだとタグ機能がついていないので、今回はタグ機能の作り方を説明していきたいと思います。

## タグ情報の追加

各記事のメタ情報は Markdown のヘッダーに記載されますが、この型は`Metadata.elm`で定義されています

```elm
type alias ArticleMetadata =
  { title : String
  , description : String
  , published : Date
  , author : Data.Author.Author
  , image : ImagePath Pages.PathKey
  , draft : Bool
  }
```

ここにタグ情報を追加していくんですが、せっかく Elm を使っているので思いっきりコンパイラの力を借りましょう。いきなりタグの型を突っ込んじゃいます。タグは複数つけたいので、List にしちゃいましょう。

```elm
type alias ArticleMetadata =
  { title : String
  , description : String
  , published : Date
  , author : Data.Author.Author
  , image : ImagePath Pages.PathKey
  , draft : Bool
  , tags : List String -- 追加
  }
```

するとたくさんコンパイルエラー起きると思うので、あとはこいつに従っていくだけです。まず同じファイル内のヘッダーの decoder がエラー起こしてるので、これを直しましょう。

```elm

decoder : Decoder Metadata
decoder =
  Decode.field "type" Decode.string
    |> Decode.andThen
      (\pageType ->
        case pageType of
          "page" ->
            Decode.field "title" Decode.string
              |> Decode.map (\title -> Page { title = title })

          "blog-index" ->
            Decode.succeed BlogIndex

          "author" ->
            Decode.map3 Data.Author.Author
              (Decode.field "name" Decode.string)
              (Decode.field "avatar" imageDecoder)
              (Decode.field "bio" Decode.string)
              |> Decode.map Author

          "blog" ->
            Decode.map7 ArticleMetadata -- 項目が増えるのでmap7に変更
              (Decode.field "title" Decode.string)
              (Decode.field "description" Decode.string)
              (Decode.field "published"
                (Decode.string
                  |> Decode.andThen
                  (\isoString ->
                    case Date.fromIsoString isoString of
                      Ok date ->
                        Decode.succeed date

                      Err error ->
                        Decode.fail error
                  )
                )
              )
              (Decode.field "author" Data.Author.decoder)
              (Decode.field "image" imageDecoder)
              (Decode.field "draft" Decode.bool
                |> Decode.maybe
                |> Decode.map (Maybe.withDefault False)
              )
              (Decode.field "tags" (Decode.list Decode.string)) -- 追加
              |> Decode.map Article

          _ ->
              Decode.fail ("Unexpected page type " ++ pageType)
      )
```

これでコンパイルエラーは直りましたが、今度は「tags フィールドが無え！」って怒られるので、書く記事に tags フィールド追加して、適当なタグを付けましょう

```json
---
{
  "type": "blog",
  "author": "Dillon Kearns",
  "title": "Hello `elm-pages`! 🚀",
  "description": "Here's an intro for my blog post to get you interested in reading more...",
  "image": "images/article-covers/hello.jpg",
  "published": "2019-09-21",
  "tags" : ["test"] -- 追加
}
---
```

これで各記事はタグデータをを持つことができるようになりました

## タグの表示

次はタグを記事のトップに表示できるようにしましょう。各記事の view 部分は`src/Page/Article.elm`に定義されてます。タグ情報は`metadata.tags`で取り出せるので、これを表示する関数を書いて view の中に加えましょう

```elm

view : ArticleMetadata -> Element msg -> { title : String, body : List (Element msg) }
view metadata viewForPage =
    { title = metadata.title
    , body =
        [ Element.column [ Element.spacing 10 ]
            [ Element.row [ Element.spacing 10 ]
                [ Author.view [] metadata.author
                , Element.column [ Element.spacing 10, Element.width Element.fill ]
                    [ Element.paragraph [ Font.bold, Font.size 24 ]
                        [ Element.text metadata.author.name
                        ]
                    , Element.paragraph [ Font.size 16 ]
                        [ Element.text metadata.author.bio ]
                    ]
                ]
            ]
        , publishedDateView metadata |> Element.el [ Font.size 16, Font.color (Element.rgba255 0 0 0 0.6) ]
        , tagsView metadata -- 追加
        , Palette.blogHeading metadata.title
        , articleImageView metadata.image
        , viewForPage
        ]
    }

tagsView : { a | tags : List String } -> Element msg
tagsView metadata =
    Element.row [ Element.spacing 10 ] (List.map Element.text metadata.tags)
```

これで表示されるはずです
!["1"](images/posts/elm-pages-tag/a.jpg)

## タグが付いた記事だけ表示する

タグがついた記事だけ表示するようにしてみましょう。今回は記事一覧ページにタグのクエリを付ける実装にします。まずタグをただのテキストからリンク付きボタンに変えましょう

```elm
tagsView : { a | tags : List String } -> Element msg
tagsView metadata =
    Element.row [ Element.spacing 10 ] (List.map tagLink metadata.tags)

tagLink : String -> Element msg
tagLink tagName =
    Element.link [] { url = "blog/?tag=" ++ tagName, label = Element.text tagName}
```

タグがクリックできるようになるのでクリックすると、ちゃんと URL にクエリが付きます

!["2"](images/posts/elm-pages-tag/b.jpg)

しかしこのままだと記事の表示が変わりません。Elm がタグのクエリを解釈していないからです。なのでタグのクエリの有無を状態として持たせて、タグボタンをクリックした時にそれを更新するといういつもの`Model View Update`を使いましょう。

elm-pages の初期テンプレートは Model も Update も使われておらず、状態を持っていません。まずは Model にクエリを持つようにさせましょう。タグのクエリを持っていない（タグをクリックしていない）場合もあるので、`Maybe String`型にしましょう

```elm
type alias Query =
    { tag : Maybe String }

type alias Model =
    Query

init : ( Model, Cmd Msg )
init =
    ( { tag = Nothing }, Cmd.none )
```

update と Msg もタグのクエリを持っている時と持っていない時で分岐させます

```elm
type Msg
    = HasQuery Query
    | NoMsg

update : Msg -> Model -> ( Model, Cmd Msg )
update msg model =
    case msg of
        HasQuery query ->
            ( query, Cmd.none )

        NoMsg ->
            ( { tag = Nothing }, Cmd.none
```

これで Model と update はできましたが、Msg はいったいどこから発行するのでしょうか？実は elm-pages にはページを移動するごとに実行される`onPageChange`という関数が用意されていて、この関数が引数として URL のクエリを受け取ることができます。この関数を使ってページ移動ごとにクエリを受け取って、それを Msg として発行します。初期テンプレートでは onPageChange を使わない設定になっているので、関数を作りつつ、`main`の`Pages.Platform.init`の`onPageChange`に入れます

```elm
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
        , onPageChange = Just onPageChange -- ここに入れる
        , internals = Pages.internals
        }
        |> Pages.Platform.withFileGenerator generateFiles
        |> Pages.Platform.toProgram

onPageChange : { path : PagePath Pages.PathKey, query : Maybe String, fragment : Maybe String, metadata : Metadata } -> Msg
onPageChange page =
    case page.query of
        Just query ->
            HasQuery { tag = Just query }

        Nothing ->
            NoMsg
```

これでクエリの有無によって Elm の状態を更新することができるようになったので、状態に応じてタグがついた記事だけ表示できるようにしましょう。

初期テンプレには記事の Markdown には draft フラグが含まれていて、`Index.elm`の`view`でフィルターを使って darft が false の記事だけ表示するようになっています。これに習ってタグが付いた記事だけ表示するフィルターを作りましょう。

```elm
view :
    List ( PagePath Pages.PathKey, Metadata )
    -> Maybe String
    -> Element msg
view posts tag =
    Element.column [ Element.spacing 20 ]
        (posts
            |> List.filterMap
                (\( path, metadata ) ->
                    case metadata of
                        Metadata.Article meta ->
                            if meta.draft then
                                Nothing

                            else
                                Just ( path, meta )

                        _ ->
                            Nothing
                )
            |> tagFilter tag -- ここにフィルター関数を差し込む
            |> List.sortWith postPublishDateDescending
            |> List.map postSummary
        )


tagFilter : Maybe String -> List PostEntry -> List PostEntry
tagFilter tag posts =
    case tag of
        Just value ->
            List.filter (hasTag value) posts

        Nothing ->  -- タグが指定されていない場合は全記事表示
            posts


hasTag : String -> PostEntry -> Bool
hasTag tag ( _, metadata ) =
    List.member tag metadata.tags
```

Elm はパイプラインのおかげでデータが流れているように見えることも、List を操作する関数がたくさんあるのも良いですね。おそらくこう書くと「view 関数が tag 引数受け取ってないぜ」ってコンパイラに言われるので、`Main.elm`の`pageView`関数の中で受け取るように変更しましょう。もともと`pageView`で Model を受け取るようになっているので、そこから tag を取り出しましょう。

```elm
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

        Metadata.Author author ->
            { title = author.name
            , body =
                [ Palette.blogHeading author.name
                , Author.view [] author
                , Element.paragraph [ Element.centerX, Font.center ] [ viewForPage ]
                ]
            }

        Metadata.BlogIndex ->
            { title = "elm-pages blog"
            , body =
                [ Element.column [ Element.padding 20, Element.centerX ] [ Index.view siteMetadata model.tag ]
                ]
            }
```

ここまで書くとコンパイルエラーが起きなくなると思うので、早速記事内のタグをクリックしてみましょう

!["c"](images/posts/elm-pages-tag/c.jpg)

記事が全く表示されなくなってしまいました。なぜでしょうか？`model.tag`の実際の値を見てみると`?tag=タグ名`となっています。つまり test というタグを選択しているこの場合だと、`?tag=test`というタグが付いている記事だけを表示することになっていますが、`test`という文字だけを取り出せるようにしたいので、クエリをデコードする関数を作りましょう。デコードする方法は様々あると思いますが、今回はたまたま見つけた[getto-systems/elm-url](https://package.elm-lang.org/packages/getto-systems/elm-url/latest/)というライブラリが簡単だったので、これを使ってデコードします

```elm
import Getto.Url.Query.Decode as Getto

onPageChange : { path : PagePath Pages.PathKey, query : Maybe String, fragment : Maybe String, metadata : Metadata } -> Msg
onPageChange page =
    case page.query of
        Just query ->
            decodeQuery query -- ここでデコードするように変更

        Nothing ->
            NoMsg


decodeQuery : String -> Msg
decodeQuery query =
    let
        tag =
            query |> Getto.split |> Getto.entryAt [ "tag" ] Getto.string
    in
    HasQuery { tag = tag }
```

これでタグが付いた記事だけ表示されるようになるはずです。実際に色んなタグを付けた記事を作ってみて試してみてください
