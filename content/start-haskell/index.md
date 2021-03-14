---
type: blog
title: Haskellに入門した
published: "2020-09-20"
description: ""
tags: ["Haskell"]
image: none
---

## Haskell との出会い

関数型言語やってみたいな～～ていうか Haskell やりてえな～～ってなんとなく前から思っていました

![image1](images/posts/start-haskell/image1.jpg)

でもなんか Haskell っていうと数学ガチ勢の人たちがやってるイメージがあって、怖くてなかなか手を出せていませんでした。そんな時、8 月にブックオフのセールがあって、どうせ 20%OFF だし何か新しい言語の本買うか～って思って手にとったのが Haskell, Rust, Scala の本でした。まあ Rust はやったことないわけじゃないしと思って候補から外して、Haskell か Scala で迷ったんですが、最後はフィーリングで Haskell の本を選びました。1200 円だったし

<block

後から知ったんですけど、この本の評価微妙なんですね。[サポートページの正誤表](https://gihyo.jp/book/2017/978-4-7741-9237-6/support)見れば分かる通り、ありえないレベルで誤植が多いし、

実際、書いてないことが自明であるかのように進んでいくので辛かったです。せめて使うパッケージ名は書いてほしかった。GitHub のサンプルコード見に行かないといけないのは面倒くさいので

## 実際 Haskell はどうだったの

覚えること多くて大変です。いやまあ Elm やったので関数型言語の書き方とかパターンマッチングとかは馴染みあったんですが、そもそも Elm やってた時は関数型言語以前にプログラミングの基礎を知らないって感じだったので、今回 Haskell やってやっと関数型言語の基本を理解できたって感じです。

### カリー化とか部分適用とか

カリー化とか部分適用もふわっとしか理解してなくて、下のコードが全然分からなくて詰まっちゃいました（hsjoish さんに助けてもらいましたが）

```haskell
data YMD = YMD Int Int Int deriving Show

countRead :: Read a => Int -> Parser Char -> Parser a
countRead i = fmap read . count i

ymdParser :: Parser YMD
ymdParser = YMD <$> countRead 4 digit <*> countRead 2 digit <*> countRead 2 digit
```

countRead は Int と Parser Char の 2 つの引数を受け取るのに、引数が i しかないのはなぜ？？？って思ったら、これ count の引数をあえて空けておいて、引数が 1 つであるように見せる部分適用なんですね。だから

```haskell
countRead i parser = fmap read (count i parser)
```

って書いても同じことになりますね

### モナド

あとモナドもやっぱり詰まりました。何となく理解できて do 記法とかも読めるようになったんですけど、数学的な理解は一切してません。とりあえず

![image2](images/posts/start-haskell/image2.png)

みたいな理解をしています。この理解でコード読めているので、多分大丈夫でしょう。

### applicative style

これも分かりづらかったです。<$>とか<\*>が出てきてこいつは何をやってるんだ？と入門書と向き合ってましたが、無理やり読んでいく中でどういう役割なのか理解していきました。Haskell 完全理解者の方にも「そういうものだと思って受け入れていったほうがいい」って言われました。

どれも今までの言語と考え方も書き方も違ったので、かなり理解に時間がかかりました。最終的には体で覚える！って感じで、無理やりコードを書いていくことでだんだんと覚えていきました。それでいいのか分かりませんが。

## これから

一応入門書にあった Haskell で ja コマンドを作るっていうお題は終わらせました。ほとんど写経と言ってもいいですが、一つ一つ理解して進めることを意識したので、だいぶ Haskell は読めるようになりました。

[![adoringonion/haskell_practice - GitHub](https://gh-card.dev/repos/adoringonion/haskell_practice.svg)](https://github.com/adoringonion/haskell_practice)

次は入門書に従って Haskell での WEB アプリをやってもいいかなと思ったんですが、それよりも前々からやってみたかった HTTP サーバーの自作を Haskell でやってみようと思います。どれくらい時間かかるか分かんないですけど
