# Unity as a Libraryのサンプルプロジェクトを試す

## Unity as a Libraryとは
Unityを使った開発は通常、アプリ全体をUnityで開発しますが、Unity as a Libraryを使用すると、
XcodeやAndroid Studioで開発したネイティブアプリ内の一部のみをUnityで開発することができます。
なお、Unity as a Library は UaaL と略します。

## Swift版サンプルプロジェクト
https://github.com/Unity-Technologies/uaal-example  
元のリポジトリ内にあるiOSプロジェクトのコードはObjective-Cで書かれています。
そこで、Objective-Cのコードをswiftに書き直したものを作りました。  
https://github.com/rakusan/uaal-example  
以下では、このswift版の方を使用します。

なお、ここではiOSについてのみ触れAndroidについては触れません（自分はまだAndroidのUaaLについては把握できていません）

## サンプルプロジェクトを試す
https://github.com/rakusan/uaal-example/blob/master/docs/ios.md  
基本的にはここに書いてある通りの手順を踏めば試せます。以下はそれを日本語で要約したものです。

### 必要なもの
- Xcodeはできるだけ新しいものを使用してください（少し古いのでも大丈夫っぽいですが）
- Unityは2022.2.5f1を推奨します


### 1. プロジェクトの取得
```git clone https://github.com/rakusan/uaal-example.git```

### 2. Unityエディタでの操作
Unityエディタで uaal-example/UnityProject を開く
BundleIDとSigning Team IDを設定
（スクショ）
プラットフォームをiOSに
（スクショ）
ビルド
（スクショ：Unity-iPhone.xcodeproj ができる）

3. Xcodeワークスペースの作成
空のXcodeワークスペースを作成 (both.xcworkspace)
（スクショ）
NativeiOSApp.xcodeproj と Unity-iPhone.xcodeproj をワークスペースに追加
（スクショ）

4. UnityFramework.framework を追加
Generalタブの"Frameworks, Libraries, and Embedded Content"に Unity-iPhone/UnityFramework.framework を追加
Build Phasesの"Link Binary With Libraries" からUnityFramework.frameworkを削除

5. NativeCallProxy.h をパブリックにする
（スクショ）

6. Dataフォルダの Target Membership を UnityFramework に変更
（スクショ）


ビルド
（スクショ）


実行時の画面の説明

初期画面
（画面のスクショ）
swiftのコードで書いたUIを表示している
（コードのスクショ）

initボタンを押すとUnityが起動
背景と豆腐、黒地に白文字のボタンはUnity側、
緑・黄・赤のボタンはswift側で出しているもの。

initでUnityを起動

Show MainでUnityを非表示に → Show UnityでUnityを表示

UnloadでUnityをアンロード → 再度 init でUnityを起動（初期状態から）

Send Msgでswift側からUnity側にメッセージを送信
Show Main with ColorでUnity側からswift側にメッセージを送信

Quit: Unityを完全に終了。以降、再度 init も不可。
