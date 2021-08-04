---
type: blog
title: "1ヶ月もかけてCA Tech Dojo サーバサイド (Go)編をRustでやってみた"
published: "2021-07-08"
description: ""
image: none
tags: ["サーバーサイド", "Rust"]
---

世間の流行りに乗っかって Rust を始めて、まあ仕事で使う簡単な CLI ツールとかは作ってたんですが、「Rust で Web 開発やってみて～」という気持ちが唐突に湧きました。特に理由はないです

Web 開発やりたいな～でも作りたいものないな～って悩んでたら、TechTrain ってところがサイバーエージェントの過去のインターンのお題を載せてくれてたんですよね。僕このインターン落ちたので嫌な記憶蘇ってはぁクソって最初は思いましたが、これを Rust で実装したら練習にちょうどええんちゃう？って思ったのでやってみることにしました。

提示された API の仕様見て、まあこれくらいなら俺でもすぐ行けるやろ！って思ってました。

**結局 1 ヶ月かかりました。**

なので、なんでこんな簡単な API 作るのに 1 ヶ月もかかったのか書いていきます

## 苦労したこと

### サーバーサイドまともにやったことがなかった

はい、一番の要因です。僕自身まともにサーバーサイドを実装したことがありませんでした。個人開発で Flask で API サーバー作ったことはありますが、POST で受け取った値を外部サービスの API に渡してその結果を返すだけの会ってないようなものでしたし、長期インターンで Spring boot や Rails を使ったことはありますが、マジで DB のこととかほぼ意識せずに言われるがまま作っててほぼ記憶にも残ってないので、実質今回が始めてでした。

本とか技術記事読んでサーバーサイド何となくの雰囲気は知ってましたが、いざやってみるともう何も分からない。DB とどうやって接続するんですか？てか接続してそれどこで保持するんですか？リクエストってどうやって受け取るんですか？リクエストヘッダーの値ってどこから取るんですか？JSON どうやって扱うんですか？レスポンスコードどれが適切なんですか？もうね、何も分からない。

特に DB が分かりませんでした。フレームワーク使った時は DB の接続とか SQL とか良い感じに隠蔽してくれててな～んも意識してなかったので、何も分かりませんでした。SQL の書き方とか、コネクションとか、テーブル定義とか、MySQL の設定方法とか、[達人に学ぶ DB 設計 徹底指南書](https://www.amazon.co.jp/dp/4798124702)を読んだり、それでも分からない時は会社のサーバーサイドの人に質問投げたりして、何とか使えるようになりました。

設計だってそこそこ本読んでたくせに、いざ実装するとなると全然分からなくなって、まあかろうじて DB の操作は Repository で隠蔽するんだよね？ぐらいのことしかできてなくて、集約がどこからどこまでなのかも分からなくなるし、どの関数がどのレイヤーに相当するのかも分からなくなっていました。

何をすればいいかは何となく浮かぶのに、その実装に至るまでに必要な前提知識が次々出てきて、VSCode 開いたはいいものの、結局ドキュメントや解説記事読むのに費やして全くコード書けなかった日がたくさんありました。虚無でした。

### そもそも Rust の理解が甘かった

簡単な CLI ツール作っただけで Rust 分かった気になって「Rust はいいぞ」とか言ってた自分が恥ずかしいくらいに何も分かっていませんでした。所有権もトレイトもエラー処理も全然分かっていなかったので、公式ドキュメントと Rust By Example をずーっと眺めていました。

### Docker が分からなかった

やっぱり誰でもすぐ動かせるように Docker 化しておくべきね、なんて思ってたので最初から Docker 使って作ってましたが、普段 Docker 使ってるって言っても自分は `docker pull` で落としてきたイメージをそのまま使ってるだけで、1 から `docker-compose.yml` や `Dockerfile` を書くってことをしてこなかったのでまあ大変でした。

散々色んな人の記事とか見て分からね～～って言ってた割に、公式のドキュメントに超丁寧な書き方チュートリアルがあるってのを後から発見しました。虚無でした。

### フレームワークやライブラリの仕様の理解に振り回された

今回は Rust の Web フレームワークに [Rocket](https://rocket.rs/) を、ORM に [diesel](https://diesel.rs/) を使いましたが、まあこれの仕様を理解するのにも時間がかかりました。普段仕事でやってる Unity とかってまあ情報量がすごく多い分、細かい実装例とかそこら中に転がっているので、それ読んで適当に理解してればまあ何とかなったんですが、公式ドキュメントと issue しかほぼ頼りがないので本当に欲しい情報にたどり着くまでに結構時間かかりました。

Rocket でリクエストヘッダーの値読み取ったり、DB を操作するには `FromRequest` ってトレイトをそれぞれ実装しなきゃいけないってことが全然分からなかったり（いやまあドキュメントに書いてあるんですが）、diesel で目的のクエリを発行するにはどういう書き方すればいいのか分からなかったり（結局分からなくて SQL を直に書いてるところもある）、公式ドキュメント読みながら途方に暮れる時間も多かったです。虚無でした。

### 方針が決まりきる前に手を動かして、集中が続かなかった

土日とかにコード書いててマジで全然集中続かなくて、もうなんかこれが自分の能力の限界なんかなって思い始めてましたが、実装方針決まりきってないのに手を動かそうとしてるから全然集中できなかっただけなんですよね。それはそう

あと設計も最初からきっちり作ったほうが良かったです。クリーンアーキテクチャとかエヴァンス本とか読んでたくせに、最初は設計とかほぼ考えず思いつくままに書いてて、まあゴチャついてきて把握が大変になって手が止まるようになってたんですが、一回数時間くらいかけてディレクトリ構成とか依存関係の方向とか全部ゴッソリ整理した後はかなりコード書くのが楽になりました。

## 技術的なことについて

このセクションに関しては、分からないなりに頑張って書いてるのでかなり間違いがあると思います。指摘があればぜひお願いします

### 設計

設計は所謂クリーンアーキテクチャを意識して作ってありますが、自分はあれは設計の一例でしかないと考えてますし、あれに書かれているレイヤーを一字一句全く同じものを作るのは正直あんまり意味ないと思ってるので、

- リクエストとレスポンスを処理する Controller
- ビジネスロジックが置かれてる UseCase
- DB への接続部分の Repository

の大まか 3 つで構成されています。フレームワークや DB に依存するものは全て `infrastructe` 以下に配置しています。

今回の要件ではユーザーとキャラクターの 2 つのドメインモデルが明確に提示されているので、それぞれの DB テーブルとその写像としてのドメインオブジェクトもすぐ作れたんですが、「ユーザーがどのキャラクターを所持しているのか」という関係性をどう表すのか（つまり中間テーブルの概念）が自分は全然分からず、またその「所持」という概念はユーザーとキャラクターどちらの集約に属していて、 Repository にどういう実装をすればいいのかということも分からなくなって、この前買ったばかりの[ドメイン駆動設計 モデリング/実装ガイド](https://booth.pm/ja/items/1835632)を読みながら、まあユーザーが所持の主体なんだからこれはユーザーの集約の中に入るんだろうと考えて実装しました。

### データベース

今回は有名なのと、Rocket が公式で対応しているということで ORM の diesel を使いましたが、diesel というか ORM そのものがとても分かりにくくて苦労しました。SQL は一応[SQL Zoo](https://sqlzoo.net/)で練習して、大体の操作はできるようになったんですが、それを ORM の文法に落とし込むのがすごく分かりづらくて大変でした。

またガチャ API の「ガチャを引いてキャラクターを取得した後、それを記録する。ユーザーは同一キャラクターを複数所持できる」という要件を満たすために、中間テーブルにはユーザーとキャラクターの外部キーの他に「枚数（quantity)」カラムを作って、既に所持しているキャラクターを INSERT する時は、代わりに quantity をインクリメントするようにしてます。そのために `ON DUPLICATE KEY UPDATE` を使いたかったんですが、diesel の MySQL ドライバーにはこれに相当するものがなく、[生 SQL を使うか DSL を自分で実装するしかない](https://github.com/diesel-rs/diesel/issues/1776#issuecomment-402986661)とのことだったので、しぶしぶ生 SQL を使っています。

また中間テーブルへの登録時、ほとんどの場合登録するキャラクターが複数存在しているので、一気に複数登録するらしいバルクインサートを使ってみたかったんですが、なかなか使い方が分からなくて、しかたなく for in でキャラクターを一つずつ取り出した後に INSERT するというかなり非効率な実装になっています

### エラー処理

エラー処理はかなり適当になっています。特にユーザートークンの妥当性検証は「値が空でないこと」「UUIDv4 の形式になっていること」ぐらいしかちゃんとチェックしておらず、トークンが DB に存在しているかどうかというチェックは実際に各クエリを実行する時に行うという形になっています。

また Rust で関数が返したエラーの内容で処理を分岐させる方法がまだ分かっていないので、現状 Rocket がリクエストを受け入れた後に起きたエラーについては、全て同じエラーがレスポンスで返ってくるようになっています。かなり問題です。

## 何とか完成したけど

まあ他にも色々細かいことで躓きまくったんですが、一応与えられた仕様通りの API はできました。でもまあ分からないまま放置してるところも結構あってゴミみたいなコードもちらほらあります。この TechTrain ってサービスは一応メンターと相談しながら課題を進めていくっていう方式なんですが、課題の設定無視して勝手に Rust で実装してる以上、あんまり相談できないので指摘とかマサカリとかプルリクとかあったらぜひお願いします

[ca-tech-dojo-rust](https://github.com/adoringonion/ca-tech-dojo-rust)

やってみた感想としては、まあ慣れない言語でほとんど全くやったことないことをやるってのはかなりしんどいです。この 1 ヶ月で学べたことはたくさんありますが、まあしんどいです。もう最後の方は飽きてきてましたし。

ただまあやっぱり Rust っていう言語はとにかくエラーが丁寧なのと、豊富なシンタックスシュガーで良い感じにコードが書けるのがとても良いので今後もどんどん使っていきたいです。まあ今はもうしばらくやりたくないので Flutter に戻ります

## 参考文献

- [達人に学ぶ DB 設計 徹底指南書](https://www.amazon.co.jp/dp/4798124702)
- [ドメイン駆動設計 モデリング/実装ガイド](https://booth.pm/ja/items/1835632)
- [Creating a REST API in Rust with Persistence: Rust, Rocket and Diesel](https://genekuo.medium.com/creating-a-rest-api-in-rust-with-persistence-rust-rocket-and-diesel-a4117d400104)