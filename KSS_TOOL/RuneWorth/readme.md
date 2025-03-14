# KSS fike making kit for Rune Worth (MSX2)

ルーンワース(MSX2版)のディスクイメージからKSSファイルを作成するツールキットです。

使用しているバッチファイルやツールの関係でWindows環境が前提です。

他の環境でやりたい場合は、中身を参考になんかしてみてください。  
（他の環境でもおそらく同等のツール類はあるはず）

## 準備が必要な物

- `RuneWorth_S.dsk` ... システムディスク ディスクイメージ
- `RuneWorth_A.dsk` ... ゲームディスク A ディスクイメージ
- `RuneWorth_B.dsk` ... ゲームディスク B ディスクイメージ
- `bincut2.exe`
  ... バイナリ切り出しツール。  
  ..... https://nezplug.sourceforge.net/  
  ..... https://www.purose.net/befis/download/nezplug/oldsite.shtml
- `AILZ80ASM.exe`
  ... 便利な Z80 Assembler
  ..... https://github.com/AILight/AILZ80ASM

これらはご自分でご用意し、すべて同じフォルダにおいてください。

## ツールキットの内容

### バッチファイル

`runeworth_make.bat`

全てのファイルを同じフォルダに置いたら `runeworth_make.bat` を実行してください。

必須ファイル一覧：
- `runeworth_make.bat`
- `RuneWorth_Player.bin`
- `RuneWorth_S.dsk`
- `RuneWorth_A.dsk`
- `RuneWorth_B.dsk`
- `bincut2.exe`

成功すれば、`Rune Worth (MSX).kss`が出来ているはずです。

そのままだと楽曲情報がなくて扱いづらいので、プレイリストを用意しました。

### kbMediaPlayer/WINAMP & MSXPlug用 プレイリスト

#### サントラに近い順番かつ、FM音源全曲→PSG音源全曲
- Rune Worth (MSX) FM-PSG.m3u
- Rune Worth (MSX) FM-PSG.m3u8

#### データの出現順（FM音源とPSG音源が交互に並んでいる）
- Rune Worth (MSX).m3u
- Rune Worth (MSX).m3u8

#### 使用法
`Rune Worth (MSX).kss`と同じフォルダに置いてください。

kbMediaPlayerはm3uファイルでもm3u8ファイルでもどちらでも使用できます。

WINAMPはm3u8ファイルを使用してください。
(m3uだと文字化けします)

foobar2000はKSS拡張プレイリスト形式に対応していません。

### その他

- `RuneWorth_Player.asm`  
  `RuneWorth_Player.bin`のソースファイル。  
  AILZ80ASMでアセンブルします。

### 未収録曲？

MSX2版は「危険がアブナイ」（サントラの 21）が入っていない様子でした。
探したのですが、見つかりません。

解析情報も少し入れてあるのでどなたかチャレンジしてみませんか？

