# fixed KSS File Extraction Kit for Rune Worth (MSX2) Complete Sound Tracks

[English Version](./en/)

ルーンワース(MSX2版)のディスクイメージからKSSファイルを作成するツールキットです。

使用しているバッチファイルやツールの関係でWindows環境が前提です。  
他の環境でやりたい場合は、中身を参考になんかしてみてください。  
（他の環境でもおそらく同等のツール類はあるはず）

## 曲リスト

一部離れた位置にあるデータなども探して、サントラ収録曲は全て網羅しました。

サントラの曲35曲＋ジングル系の曲が4曲。  
それぞれOPLL版とPSG版があります。

01. サリスの滅亡
02. ルーンワースのテーマ
03. 旅立ち
04. ザノバ砦
05. 神聖サイア王国
06. ウェイデニッツ公国
07. バハマーン神国
08. シャタパーサ連邦
09. ウェーデル山脈
10. おーたま
11. 祈り
12. もったいない
13. 5時からの男のために
14. 死んでしまった
15. KANA-P
16. もっと KANA-P
17. URE-P
18. ミリムはオ・ト・ナ
19. うろわば！
20. 神々のガミガミ
21. 危険がアブナイ
22. 永久凍土
23. オールマムの野望
24. 戦慄の魔導士
25. あやかしの塔
26. サータルスの導き
27. 無法都市
28. ラマスカエル燃ゆ
29. エリースの涙
30. 暗殺魔術団ヴィーフォ
31. 暗黒からの脱出
32. 限りなき戦い
33. 邪神復活
34 やすらぎ
35. 明日がふり返る

36. * GAME OVER
37. * 宝箱ゲット
38. * ファンファーレ
39. * リカルトの竪琴


## 準備が必要な物

- `RuneWorth_S.dsk` ... スタートディスク ディスクイメージ
- `RuneWorth_A.dsk` ... ゲームディスク A ディスクイメージ
- `RuneWorth_B.dsk` ... ゲームディスク B ディスクイメージ
- `bincut2.exe`
  ... バイナリ切り出しツール。  
  ..... https://nezplug.sourceforge.net/  
  ..... https://www.purose.net/befis/download/nezplug/oldsite.shtml
- `AILZ80ASM.exe`
  ... 便利な Z80 Assembler
  ..... https://github.com/AILight/AILZ80ASM

これらはご自分で用意し、すべて同じフォルダにおいてください。

## MDTファイルの切り出し（MSXでの演奏用）

### MDT切り出しバッチファイル

- `RuneWorth_extract_mdt.bat`

### 必須ファイル一覧

- `RuneWorth_extract_mdt.bat`
- `RuneWorth_S.dsk`
- `RuneWorth_A.dsk`
- `RuneWorth_B.dsk`
- `bincut2.exe`

サブフォルダ`RuneWorh_mdt`を作成し、
曲データをmdtファイルとして切り出します。  

成功すると
- `RuneWorth_OPLL` フォルダにOPLL用mdtファイル
- `RuneWorth_PSG` フォルダにPSG用mdtファイル
がそれぞれ出力されていると思います。

[MSXFAN 1995年6月号付録ディスク#32-1収録の「アンデッドライン」BGMツール一式](#アンデッドラインbgm集mml開発キット)に同梱の
- PSG.COM
- OPLL.COM

で試聴できます。

`RuneWorth_extract_mdt.bat`でmdtファイル切り出す時に、
試聴用バッチファイル `PLAY-P.BAT`、`PLAY-O.BAT`も生成します。

`PLAY-P.BAT`がPSG曲用、
`PLAY-O.BAT`がOPLL曲用です。

> [!CAUTION]
>   [**OPLL.COMはR800モードでは演奏がおかしくなります。**](#oplcomの注意点)  

## KSSファイルの切り出し（MSX以外での演奏用）

### KSS作成バッチファイル

`RuneWorth_kss_maker.bat`

全てのファイルを同じフォルダに置いたら `RuneWorth_kss_maker.bat` を実行してください。

### 必須ファイル一覧

- `RuneWorth_kss_maker.bat`
- `RuneWorth_kss_head.bin`
- `RuneWorth_S.dsk`
- `RuneWorth_A.dsk`
- `RuneWorth_B.dsk`
- `bincut2.exe`

成功すれば、`Rune Worth (MSX).kss`が出来ているはずです。

## KSSファイルの試聴方法

KSSだけだと楽曲情報がなくて扱いづらいので、プレイリストを用意しました。

### kbMediaPlayer / WINAMP / foobar2000 プレイリスト

プレイリスト

- サントラに近い順番 / FM音源全曲→PSG音源全曲の順
  - Rune Worth (MSX).m3u
  - Rune Worth (MSX).m3u8

- データの出現順のもの（FM音源とPSG音源が交互に並んでいる）
  - Rune Worth (MSX) RAW.m3u
  - Rune Worth (MSX) RAW.m3u8

`Rune Worth (MSX).kss`と同じフォルダに置いてください。

- kbMediaPlayer

  - m3uファイルでもm3u8ファイルでもどちらでも使用できます。

  - kss対応のMSXPlugは最初から入っています。

- WINAMP

  - m3u8ファイルを開いてください。 (m3uだと文字化けします)

  - kss対応のMSXPlug(in_msx)が必要です。  
    https://github.com/digital-sound-antiques/in_msx  

- foobar2000

  - プレイリストではなく`Rune Worth (MSX).kss`を開いてください。  
    自動で同じフォルダにある同じ名前のm3uプレイリストを読み込みます。  

  - KSSファイルの再生にはGameEmuPlayer(foo_gep)プラグインか、  
    NPNEZ(foo_npnez)プラグインが必要です。  
  
    - GameEmuPlayer(foo_gep)
      https://www.foobar2000.org/components/view/foo_gep  

    - NPNEZ(foo_npnez)
      https://ux.getuploader.com/foobar2000/
      別途nezplug++同梱のnpnez.dllが必要。  
      foo_npnez.dllと同じ場所に置く。
      詳細は付属のドキュメント参照。


## ルーンワースMSX版の音

MSX版ルーンワースはPSGもOPLL版もかなり凄い音を出していて、PSGやOPLLの特性に合わせて調整された楽曲群は、他音源とは違う良さを持っています。

サイオブレード、レイドック２、アンデッドラインを経て磨き上げた技術の最終版がこのルーンワースの楽曲データと言えます。

MSX音源のサントラは存在せず、ミュージックディスクもごく一部の人間しか所有していないため、ゆっくり全曲聞くというのが難しい状況でした。

クラシカルなゲームの音楽を実物に出来るだけ近い音で手軽に楽しみたいという需要は昔から存在し、ゲームイメージから音源データとドライバを抜き出して仮想マシンで実行演奏させるという仕組みが考えられました。

その一つがKSSファイルです。KSSは様々な拡張を経てMSXに対応しています。
KSSを作成するには解析と抽出が必要ですが、その作業をまとめて実行できるファイルと言うのが存在しました。

ところが、ルーンワースMSX版の場合解析が不完全なのか、そのKSS作成ツールキットを使用して作成したKSSには全曲入っていなかったのです。

致命的な事にOP曲も入っておらず、フィールド曲も１曲足りません。
（あとは、宝箱を開けたときの曲も入っていませんでした）

そこで、自分で再解析し、足りない曲などを探して追加しました。
ループの有無対応なども追加。
プレイリストも作成して、演奏時間も調整してあります。


## アンデッドラインBGM集&MML開発キット


**MSXFAN 1995年6月号 付録ディスク#32-1**「すぺしゃる」コーナーに、
**アンデッドラインBGM集&MML開発キット一式**(`UNDEAD.LZH`)
が収録されています。

MMLコンパイラとDOSコマンドライン用プレイヤー、MML、BGMバイナリのセット一式です。

> mdt切り出しツール  
> RuneWorth_extract_mdt.bat
  

### MMLコンパイラ  

  - まとめてコンパイル
    - CMP-O.BAT
    - CMP-P.BAT
  
  - 本体
    - MDC3A.COM
    - MDC.COM
    
  - 1曲コンパイル＆演奏
    - O.BAT
    - P.BAT

### BGMプレイヤー

  - 全曲演奏
    - PLAY-O.BAT
    - PLAY-P.BAT
  
  - プレイヤー本体
    - OPLL.COM
    - PSG.COM

  ※ ゲーム組み込み向けドライバは非公開

#### OPL.COMの注意点
  
> [!CAUTION]
>   **OPLL.COMはR800モードでは演奏がおかしくなります。**  
>   Z80での動作が必要なので、ターボRの場合は
>   [CHGCPU.COM](https://github.com/hra1129/msx_tools/tree/main/chgcpu)
>   等を使用してZ80に切り替えてから使用してください。  

#### MML

PSG音源用MML

| ファイル名   | 内容                     |
|--------------|--------------------------|
| OP1-P.PSG    | オープニング             |
| OPEN-P.PSG   | オープニング             |
| MENU1-P.PSG  | タイトル                 |
| MENU2-P.PSG  | キャラ、ステージセレクト |
| DEMO-P.PSG   | 中間デモ                 |
| BGM1-P.PSG   | FORESTステージ           |
| BGM2-P.PSG   | CEMETERYステージ         |
| BGM3-P.PSG   | RUINSステージ            |
| BGM4-P.PSG   | ROCKSステージ            |
| BGM5-P.PSG   | CAVERNステージ           |
| BGM6-P.PSG   | DUNGEONステージ          |
| BGM7-P.PSG   | FORTRESSステージ         |
| BOSS1-P.PSG  | ボス                     |
| BOSS2-P.PSG  | 最終ボス                 |
| CLEAR-P.PSG  | ステージクリア           |
| OVER-P.PSG   | ゲームオーバー           |

FM音源用MML

| ファイル名   | 内容                     |
|--------------|--------------------------|
| OP1-O.OPL    | オープニング             |
| OPEN-O.OPL   | オープニング             |
| MENU1.OPL    | タイトル                 |
| MENU2.OPL    | キャラ、ステージセレクト |
| DEMO.OPL     | 中間デモ                 |
| CONFI.OPL    | ハイスコア表示           |
| BGM1.OPL     | FORESTステージ           |
| BGM2.OPL     | CEMETERYステージ         |
| BGM3.OPL     | RUINSステージ            |
| BGM4.OPL     | ROCKSステージ            |
| BGM5.OPL     | CAVERNステージ           |
| BGM6.OPL     | DUNGEONステージ          |
| BGM7.OPL     | FORTRESSステージ         |
| BOSS1.OPL    | ボス                     |
| BOSS2.OPL    | 最終ボス                 |
| END1.OPL     | エンディング             |
| ENDING.OPL   | エンディング             |
| CLEAR.OPL    | ステージクリア           |
| OVER.OPL     | ゲームオーバー           |
| MATUSI-1.OPL | ?                        |
| MATUSI-2.OPL | ?                        |

#### コンパイル済みBGMデータバイナリ

- *.MDT

ルーンワースのBGMデータもMDT形式。

#### MML機能解説（不完全版）

開発からかなり時間が経ってからの雑誌掲載の為、
詳細は忘れているとのこと。

各自解析して遊んでくださいという内容。

##### 基礎

- MMLファイル先頭行
  - `.rhythm`  ... リズムアリ
  - `.psg`     ... PSG音源用

- MMLファイル最終行
  - `.end`を書く

- 1チャンネルずつ""で囲んで書く
  - PSGは3Ch.
  - OPLLは7Ch.
  - ""で囲まれたブロックをチャンネル数分並べる
  - 1周したらまた1chからの指定に戻る

- PSG音色やOPLLユーザー音色は最後に書く
  - PSG音色定義の詳細は不明

イメージ)
```
.psg
--- intro ---
"1ch" "2ch" "3ch" 
--- loop A ---
"1ch" "2ch" "3ch" 
--- loop B ---
"1ch" "2ch" "3ch" 
--- end ---
";" ";" ";" 

--- voice data ---
data1	$dc,$ba,$86,$41,$11,$11,$11,
    	$11,$11,$11,$11,$11,$11,$11;

.end
```

##### 特殊なMML記号

| MML記号          | 機能                                |
|------------------|-------------------------------------|
| [ ① ]0 ② ]1 ② | ループ（①→②→①→③）            |
| (n)              | 音長指定を括弧で囲むと1/60秒単位    |
| @ (@のみ)        | 全チャンネルが揃うまで待つ          |
| $n               | PSG音色指定                         |
| @n               | OPLL色指定                          |
| un               | OPLLユーザー音色データ書き込み      |
| {ラベル名}       | サブルーチン呼び出し                |
| /ラベル名/       | メロディ用サブルーチンラベル        |
| \|ラベル名\|     | リズム用サブルーチンラベル          |
| %                | サブルーチンから復帰                |
| ;                | 終了                                |
| i                | デチューン                          |
| M                | ビブラート（パラメータは不明）      |
| p                | ポルタメント？                      |
| -                | コメントアウト記号                  |
| *                | 謎のコマンド                        |

- ユーザー音色を使う場合は
  ユーザー音色データを書き込んでから
  ユーザー音色に切り替えるので、
  `u0@0`の様に書く。

## おまけ：KSSヘッダのソースコード

- `RuneWorth_kss_head.asm`  

  `RuneWorth_kss_head.bin`のソースファイル。  
  AILZ80ASMでアセンブルします。

## 謝辞

音源ドライバとの橋渡しは先人の解析情報のおかげで出来ています。

この場を借りて御礼申し上げます。
