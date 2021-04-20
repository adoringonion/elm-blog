---
type: blog
title: PocoをOculusに対応させてみる
published: "2021-04-20"
description: ""
tags: ["テスト", "Unity", "Airtest", "Poco"]
image: "none"
---

昨年の CEDEC でも[取り上げられた](https://speakerdeck.com/sgeengineer/airtesttopocotoopenstfniyoruunityzhi-sumatohuonxiang-kegemufalseshi-ji-zi-dong-tesutohuan-jing-gou-zhu-tosofalseli-yong-fang-fa) ゲーム向け E2E テストライブラリの Airtest ですが、Poco というライブラリを合わせて使うことで Unity とか UE4 のゲーム中のオブジェクトを Airtest から直接操作できるようになります。

Unity だと GameObject を名前で指定して座標を取得したり、TextForm に文字入力したりとか色々できて便利なんですが、[ライブラリの中覗くと](https://github.com/AirtestProject/Poco/blob/master/poco/drivers/unity3d/unity3d_poco.py)VRSupport なる文字が見える通り、VR にも対応しようとしているんですよね。ただ[該当するドキュメント](https://github.com/AirtestProject/Poco/blob/master/doc/unity3d_vr.rst)を見てみると、「Google VR にしか対応してないよ！他の VR にも対応したいね！」って書いてある通り、Oculus とか SteamVR とかには未だ対応していません。

なので今回はライブラリの実装をイジって Oculus に無理やり対応させてみようと思います。

## 実装

まずはさっきのドキュメントの通りに、Airtest で Poco の VR API を呼び出せるようにします。

```python
from airtest.core.api import *
from poco.drivers.unity3d import UnityPoco

poco = UnityPoco()
vr = poco.vr
```

これで VR 関連の API を呼び出せるようになりました。使える API は `hasMovementFinished()` `rotateObject()` `objectLookAt()` の 3 つです。今回は `objectLookAt()`を使ってみます。

```python
def __init__(self, client):
    self.client = client
    self.support_vr = False
    try:
        self.support_vr = self.client.call("isVrSupported")
    except InvalidOperationException:
        raise InvalidOperationException('VR not supported')

### 中略 ###

def objectLookAt(self, name, camera, follower, speed=0.125):
    return self.client.call("ObjectLookAt", name, camera, follower, speed)
```

実装見てみると、RPC を介して Unity アプリに埋め込まれた Poco の SDK と通信しています。まずコンストラクタで SDK 側の`isVrSupported`ってメソッドを呼び出して、対応している VR かどうか確認しつつ、`ObjectLookAt`ではメソッドを呼び出して引数渡しているようです。今度は SDK 側の対応するメソッドを見てみます。

```csharp
void Awake()
    {
        Application.runInBackground = true;
        DontDestroyOnLoad(this);
        prot = new SimpleProtocolFilter();
        rpc = new RPCParser();
        rpc.addRpcMethod("isVRSupported", vr_support.isVRSupported);
        rpc.addRpcMethod("hasMovementFinished", vr_support.IsQueueEmpty);
        rpc.addRpcMethod("RotateObject", vr_support.RotateObject);
        rpc.addRpcMethod("ObjectLookAt", vr_support.ObjectLookAt);
```

`PocoManager`を見ると、`Awake()`でメソッドを紐付けていることが分かります。まず`isVRSupported`から見ます。

```csharp
    public object isVRSupported(List<object> param)
    {
#if UNITY_3 || UNITY_4
        return false;
#elif UNITY_5 || UNITY_2017_1
        return UnityEngine.VR.VRSettings.loadedDeviceName.Equals("CARDBOARD");
#else
        return UnityEngine.XR.XRSettings.loadedDeviceName.Equals("CARDBOARD");
#endif
    }

```

どうやら `CARDBOARD` にしか対応していないですね。本気で使うなら色んなプラットフォームに対応できるように書いたほうがいいんですが、面倒くさいので `Oculus` に書き換えてしまいましょう。

```csharp
        return UnityEngine.XR.XRSettings.loadedDeviceName.Equals("Oculus");
```

次は ObjectLookAt を見ていきます。

```csharp
public object ObjectLookAt(List<object> param)
{
    float speed = 0f;
    if (param.Count > 3)
        speed = Convert.ToSingle(param[3]);
    foreach (GameObject toLookAt in GameObject.FindObjectsOfType<GameObject>())
    {
        if (toLookAt.name.Equals(param[0]))
        {
            foreach (GameObject cameraContainer in GameObject.FindObjectsOfType<GameObject>())
            {
                if (cameraContainer.name.Equals(param[1]))
                {
                    foreach (GameObject cameraFollower in GameObject.FindObjectsOfType<GameObject>())
                    {
                        if (cameraFollower.name.Equals(param[2]))
                        {
                            lock (commands)
                            {
                                commands.Enqueue(() => recoverOffset(cameraFollower, cameraContainer, speed));
                            }

                            lock (commands)
                            {
                                commands.Enqueue(() => objectLookAt(cameraContainer, toLookAt, speed));
                            }

                            return true;
                        }
                    }
                }
            }
        }
    }
    return false;
}
```

1 番目の引数と同名のオブジェクトを全探索して、見つかったら次に 2 番目の…って処理を 3 回繰り返しています。ここが問題なんですが 2 番目と 3 番目の引数に入る `cameraContainer` と `cameraFollower` はどうやら Cardboard のカメラオブジェクト特有の構造に合わせたものらしいんですよね（僕は Cardboard 触ったことないですし、ドキュメントにそう書いてあるとしか言えないんですが…）

今回は Oculus のカメラオブジェクトである `OVRCameraRig` を任意のオブジェクトに向けたいだけなので、思い切って Airtest 側の Poco と Unity 側の PocoSDK から `cameraFollower` とそれに関するものを全部消してしまいます。

```python
def objectLookAt(self, name, camera, speed=0.125):
    return self.client.call("ObjectLookAt", name, camera, speed)
```

```csharp
public object ObjectLookAt(List<object> param)
{
    float speed = 0f;
    if (param.Count > 3)
        speed = Convert.ToSingle(param[3]);
    foreach (GameObject toLookAt in GameObject.FindObjectsOfType<GameObject>())
    {
        if (toLookAt.name.Equals(param[0]))
        {
            foreach (GameObject cameraContainer in GameObject.FindObjectsOfType<GameObject>())
            {
                if (cameraContainer.name.Equals(param[1]))
                {

                    lock (commands)
                    {
                        commands.Enqueue(() => objectLookAt(cameraContainer, toLookAt, speed));
                    }

                    return true;
                }
            }
        }
    }
    return false;
}
```

そして実際にカメラオブジェクトの操作を行っているのは `ObjectLookAtObject()` メソッドですが、ここでは引数で渡した回転速度を `transform.LookAt()` を直接使わずに `Quaternion.LookRotation()` と `Quaternion.Lerp()`　を使って対象となるオブジェクトにカメラを向ける実装になっています。

今回は元の実装をできるだけ変えないようにしようと思っていたんですが、なぜかこの実装だと`OVRCameraRig`が動かなかったので、改めて `transform.LookAt()` を使ってカメラを向けさせています。（誰か原因教えてください…）

```csharp
protected bool ObjectLookAtObject(GameObject go, GameObject cameraContainer, float rotationSpeed = 0.125f)
{
    if (null == go || null == cameraContainer)
    {
        Debug.Log("exception - item null");
        return false;
    }

    var toRotation = Quaternion.LookRotation(go.transform.position - (cameraContainer.transform.localPosition));
    cameraContainer.transform.rotation = Quaternion.Lerp(cameraContainer.transform.rotation, toRotation, rotationSpeed * Time.deltaTime);

    cameraContainer.transform.LookAt(go.transform); // 追加
    // It should not be needed but sometimes the difference of eurlerAngles might be small and this would ensure it works fine
    if (Quaternion.Angle(cameraContainer.transform.rotation, toRotation) == 0)
    {

        return false;
    }

    return true;
}
```

後はシーンに`OVRCameraRig` と適当なオブジェクトを配置して、Airtest のコードを書けば動きます。

```python
from airtest.core.api import *
from poco.drivers.unity3d import UnityPoco

auto_setup(__file__)

poco = UnityPoco()
vr = poco.vr

vr.objectLookAt('CubeA', 'OVRCameraRig')
sleep(2)
vr.objectLookAt('CubeB', 'OVRCameraRig')
sleep(2)
vr.objectLookAt('CubeC', 'OVRCameraRig')
```

![VR画像](images/posts/poco-oculus/poco.gif)

## まとめ

今回はもともとあった VR 用 API を無理やり Oculus に対応させましたが、独自に実装することで何でもすることができます。独自の API を実装する方法は参考資料のほうが詳しいので、そちらをぜひ見てください。

## 参考資料

[Airtest と Poco を拡張して、Component のメソッドを直接実行する。](https://qiita.com/mmm_hiro/items/f6776d3458f767cf9d09)
