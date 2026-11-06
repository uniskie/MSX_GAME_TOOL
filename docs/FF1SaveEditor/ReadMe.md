# FC版・MSX版対応 ファイナルファンタジーⅠ セーブデータエディタ

オンラインから実行：  
<https://uniskie.github.io/MSX_GAME_TOOL/FF1SaveEditor/ff1_editor.html>

- MSX版 : ユーザーディスクをエディタウィンドウにドロップしてください。
- FC版  : SAVファイルをエディタウィンドウにドロップしてください。  
          ※ 特殊なヘッダがついたセーブデータの場合は、ヘッダを除去したものをドロップしてください。
          　 たとえばレトフリのセーブデータは余計なものがついてます。

編集が終わったら保存ボタンをおすとダウンロードフォルダに編集後のセーブデータが保存されます。

![screenshot](screenshot.png)

## 簡易ガイド

### 名前入力

ゲーム中で使用できる文字を受け付けるのでカタカナも使えます。

カタカナの小さい「ゥ」などはゲーム中にフォントが存在しないので「ウ」などに強制変更されます。

### [地図]

おまけ的な機能です。

初期状態では簡易的なマップ表示ですが、ROMを読み込ませると正確なマップが表示できます。

簡易表示の場合

- ff1_editor_world_map.png
- ff1_editor_world_sprites.png

を使用して表示します。

### パラメータ自動計算

レベル変更時、成長テーブルに従ってパラメータを自動計算します。

テーブルはLV50までなので、上限制限を無効にしても自動計算が有効な時はLV上限が50までとなります。

### ファミコン版カートリッジを所有していてダンプ出来る方

ダンプしたNESロムファイルをドロップすると（本当に）ちょっとした機能が強化されます。

- グラフィックがROMから読み込んだものに変わります。
- 成長テーブルやアイテムテーブルがROMから読み込んだものに変わります。
- [地図]ボタンで表示されるワールドマップが正確に表示できるようになります。

---

# MSX版推奨パッチの紹介

## Final Fantasy MSX Performance Patch

<https://github.com/abekermsx/Final-Fantasy-MSX-Performance-Patch>

MSX2版がフレームレート制限の解除と速度最適化により、移動が快適になるパッチです。  

MSX2/2+でも大きな効果がありますが、MSX turboRではさらに快適になります。
場所によっては速すぎて困るケースも？

メッセージウィンドウの表示速度まで高速になるので、会話ウィンドウ開閉時の音に違和感は出ますが、
基本的に全体が快適になります。

VDPの処理がボトルネックなので、もともと処理落ちするところはやっぱり処理落ちします。（無改造よりマシですが）

---

## MSX2版 BGM割り当て修正パッチ

[FF1-1-BGM_Fix.ips](FF1-1-BGM_Fix.ips)

MSX2版ファイナルファンタジーは
ダンジョンのBGMがファミコン版と異なる曲が鳴る場所がいくつかあります。

ファミコン版を遊んだ人は、それなりに違和感を感じると思うので、
ファミコン版準拠のBGM割り当てに修正するパッチを作りました。

| マップ         | MSX2版      | ファミコン版 |
| :------------- | :---------- | :----------- |
| カオスの神殿   | KAITEI.BGM  | KAOSS.BGM    |
| 沼の洞窟       | MATOOYA.BGM | RANCHON.BGM  |
| ミラージュの塔 | GURUGU.BGM  | RANCHON.BGM  |
| 海底神殿       | KAITEI.BGM  | KAOSS.BGM    |
| ラスダン       | KAOSS.BGM   | KAITEI.BGM   |
| 巨人の洞窟     | KAOSS.BGM   | GURUGU.BGM   |

解析の詳細を知りたい物好きは[ff1_msx_bgm_memo.md](ff1_msx_bgm_memo.md) をどうぞ。

---

# ファミコン版用ROMエディタの紹介

## HAKKINFF1 (※推奨)

<https://hakkinff1.digitaldreamers.org/index.html>

FFHackSterEXにインスパイアされたROMエディタ。

FFHackSterEXでは動かないマップ系機能がこちらでは動きます。
その代わり、**Armor**、**Weapon**、**Magic**が**日本語版ROMではエラー**になるようです。

- **日本版向け文字定義ファイル**

  [for_HAKKINFF1/](for_HAKKINFF1/)

  ROMを読み込んで作成されたプロジェクトフォルダにある  
  `(プロジェクト名).ff1d`  
  の中に、文字コードに対する文字リストがあります。

  `for_HAKKINFF1/FinalFantasy1.ff1d`を
  プロジェクト名に合わせてリネームしてプロジェクトフォルダに上書きしてください。

  プロジェクトで文字が正常に表示されるようになります。

  メニュー等も日本語化したい場合はff1dファイルを弄れば出来ると思われます。

## FFHackSterEX (※非推奨)

<https://ffhacksterex.digitaldreamers.org/>

FFHackSterの後継版です。

開発途中で止まっており、
ローカルマップ系機能や幾つかの機能がエラーで落ちます。  



- **日本版向け文字定義ファイル**

  [for_FFHackSterEX/](for_FFHackSterEX/)

  ROMを読み込んで作成されたプロジェクトフォルダにある  

  - `(プロジェクト名).dte.tbl`  
  - `(プロジェクト名).std.tbl`  

  に、文字コードに対する文字リストがあります。

  - `for_FFHackSterEX/FinalFantasy1.dte.tbl`  
  - `for_FFHackSterEX/FinalFantasy1.std.tbl`  

  をプロジェクト名に合わせてリネームしてプロジェクトフォルダに上書きしてください。

  プロジェクトで文字が正常に表示されるようになります。

  （`●●.dte.tbl` と `●●.std.tbl` は、UTF-8ではなくSJISテキストファイルです。）

- 注意事項

   ROMファイル名やパスには日本語を使わないでください。エラーになります。

---

# Binary Editor Bz - MSX Custom 向け エンコード定義ファイル

**Binary Editor Bz - MSX Custom**  
<https://github.com/uniskie/MSX_MISC_TOOLS/tree/main/BinaryEditorBz_for_MSX>

「ツール」→「カスタムエンコードの編集」でフォルダが開くので、
そこへ

[for_BzEditor_MSX_Custom/](for_BzEditor_MSX_Custom/) の中にあるファイル

- FF1.def
- FF1_oped_FC.def
- FF1_oped_MSX.def

をコピー。


