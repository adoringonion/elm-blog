---
type: blog
title: "Jenkinsのdeclarative pipelineでBranch Indexビルドを回避する"
published: "2020-12-03"
description: ""
image: none
tags: ["Jenkins"]
---

今さらJenkinsかよ！って感じかもだけど、日頃お世話になってるし、どこにも書いてないのでメモっておきます。

## declarative pipelineの面倒臭いところ

Jenkinsで複数のブランチに跨るジョブを作りたい時は現状declarative pipelineを使うしかないんですが、こいつのやっかいなところは一回ジョブを走らせないとブランチを認識しないんですよね。作ったばかりのブランチをpushしてWebhookとかでジョブ叩こうとすると「そんなブランチはねえ！」って怒られます。まあJenkinsの画面から直接ジョブを実行すればいいんですが、Slackコマンドとかでジョブを叩けるようにしてると煩わしくなります。

まあそれでdeclarative pipelineにはBranch Indexっていう定期的にジョブを走らせてブランチを認識してくれる機能があるんですが、これはこれでブランチ作る度にジョブを走らせるので面倒です。毎回毎回E2Eテストやられてたら大変です。

## 回避方法

Branch Indexだけさせてジョブは走らせないようにするには以下のように設定します

```groovy
def boolean isCausedByBranchIndexing() {
  return currentBuild.getBuildCauses()[0].shortDescription.toString() == 'Branch indexing'
}

if (isCausedByIndexing()) {
  currentBuild.result = "ABORTED"
  return
}

pipeline {
  agent any

```

```currentBuild.getBuildCauses()```でジョブの起動理由を取得できるので、それが"Branch Index"だった時にtrue返すフラグを作ればいいです。ポイントはpipelineより上に条件判定を書くことです。stageの中でreturnしてもそのstageが終わるだけなので。```currentBuild.result```をSUCCESSEDにするかABORTEDにするかはお好みでどうぞ
