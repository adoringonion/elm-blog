---
type: blog
title: JenkinsからGitLab CIへの移行メモ
published: "2021-04-13"
description: ""
tags: ["CI/CD", "Jenkins", "GitLab"]
image: "none"
---

最近、秘伝のタレ化した Jenkins から GitLab CI への移行作業をやったので、Tips 的なものを書いていきます。

Jenkins から GitLab CI への移行ガイドは[公式](https://gitlab-docs.creationline.com/ee/ci/jenkins/)のものがあるので、基本的にそちらを見てもらえればいいんですが、そこに書いてない細かいところを書いていこうと思います。

あと自分は Jenkins を Declarative Pipeline でしか使ったことがないので、以後はそれを前提に話していきます。

## パラメーター設定の違い

Jenkins ではパイプラインでパラメーターを使いたい場合は事前に定義しなければいけませんが、GitLab CI では好きなパラメーターをパイプライン実行ごとに渡すことができます。これは Jenkins に対する GitLab CI の利点として公式が謳っています。

しかし何も設定しないと使用するパラメーターを毎回設定しなきゃいけません。 `variables` にデフォルト値を定義しておくのもいいんですが、これだと GitLab の GUI から手動でパイプラインを実行する時に、デフォルト値を上書きしたいパラメーターのキーを毎回入力しなきゃいけません。![test](images/posts/jenkins-to-gitlab/a.jpg)

こういう時は[Prefill variable](https://docs.gitlab.com/ee/ci/pipelines/index.html#prefill-variables-in-manual-pipelines)を使うと便利です。キーの入力の手間が省けるだけでなく、それぞれのパラメーターの説明もつけられるので、普段 CI 触らない人でも気軽に叩くことができるようになります

```yaml
variables:
  DEPLOY_ENVIRONMENT:
    value: "staging" # Deploy to staging by default
    description: "The deployment target. Change this variable to 'canary' or 'production' if needed."
```

## ジョブ間の共有

Jenkins ではパイプラインの始まりから終わりまで同じ環境で実行されますが、GitLab CI はジョブごとにリセットされる前提で動きます。なので何も設定しないと毎ジョブごとに `git clone` します。ダルいです。`variables`で`GIT_STRATEGY`って変数を定義すると`clone` `fetch` `none` から git の振る舞いを選ぶことができます。なので成果物をデプロイしたいだけのジョブとかでは `GIT_STRATEGY: none` に設定しておくほうがいいです。また `variables` はパイプライン全体だけでなくジョブごとにも設定できます。

あと次のジョブにビルドした成果物を渡したい時は `artifacts` を使います。セルフホストランナーだと `$HOME/builds` 以下にパイプラインのキャッシュが残ってるので必要ないかもですが、キャッシュ消した時にジョブが成立しなくなっちゃうので設定したほうが良いと思います。

## 並列実行

Jenkins の Declarative Pipeline でジョブの並列実行をする時は `parallel` ブロックの中に`stage`を書いていく必要がありますが、GitLab CI では特に設定しないと同じ stage のジョブは自動的に並列実行されるようになります。

```yaml
stages:
  - build
  - test
  - deploy
```

↑ の設定の場合だと、並列した`stage: build`のジョブが全て終わると`stage: test`のジョブが並列実行されます。

また `parallel` と `matrix` を使うと、一つのジョブ設定で複数バージョンのジョブを並列実行することができます。

[GITLAB CI の MATRIX を使ってみた](https://sky-joker.tech/2020/12/06/gitlab-ci%E3%81%AEmatrix%E3%82%92%E4%BD%BF%E3%81%A3%E3%81%A6%E3%81%BF%E3%81%9F/)

また GitLab-Runner は初期設定では並列実行上限が 1 になっているので、並列実行したい場合は上限を上げましょう。上げすぎるとリソースを食ってジョブの時間が伸びちゃいます。またジョブに tag を指定しておくと、その tag が付いたランナーが複数ある場合には GitLab が自動的に並列ジョブを振り分けてくれます。

## ログ出力上限

GitLab CI でもセルフホストした GitLab-Runner ではログの出力上限があるので、あんまりログを出しすぎると `Job's log exceeded limit of 4194304 bytes.`ってエラー出てジョブが止まってしまいます。ログの上限は GitLab-Runner の設定ファイルから変更できます。

[GitLab CI/CD 機能における出力ログ上限の超過対策](https://qiita.com/gzock/items/a99838f5646a8d6ae887)
