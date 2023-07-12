﻿## 概要

MSXFAN 1992年10月号 付録ディスク#13収録 の  
MSX2用イドライド用置き換え画像作成＆実行セット


1. フォントをHYDLIDE3のエンディングフォントに置き換えものを作成
1. MSXFANの拡張ベーシックを使用せずに起動できるようにします。
1. おまけでタイトルの妖精を丸和太郎に置き換えた画像を作成

## 準備

付録ディスクから画像ファイルを展開しSC8ベタファイルで保存をします。
その後、元画像に差分画像を合成してパッチ済み画像を保存します。

### 必要なファイル

MSXFAN 1992年10月号 付録ディスク#13 から
1. INIT.XB
1. MSXFAN.BIN
1. LOADER.BIN
1. TITLE.XV8
1. VRAM-2.XV8

パッチ差分画像
1. TITLEMD.SC8
1. VRAM-2MD.SC8

SC8保存&パッチ当てプログラム
1. MAKESC8.XB

### 実行手順

1. 上記の必要なファイルを用意する
2. ```RUN"INIT.XB"```を実行してBASIC拡張する
3. ```RUN"SAVESC8.XB"```を実行する

### 生成されるファイル

1. TITLE.SC8 ... オリジナルのタイトル画像BSAVEファイル
1. VRAM-2.SC8 ... オリジナルのゲーム用画像BSAVEファイル
1. TITLEM.SC8 ... 妖精がまるわたろうに変更されたタイトル画像BSAVEファイル
1. VRAM-2M.SC8 ... フォントが変更されたゲーム用画像BSAVEファイル

### MAKESC8.XB

```
1 ' SAVE to SC8
2 '
3 CLEAR 99,USR8(37)
4 COLOR ,0,0:SCREEN 8,2
5 '
6 _XUNPACKS("TITLE   xv8",0)
7 BSAVE "TITLE.SC8",0,&HD3FF,S
8 SETPAGE1,1
9 BLOAD"TITLEMD.SC8",S
10 SETPAGE0,0
11 COPY(0,0)-(255,211),1TO(0,0),0,TPSET
12 BSAVE "TITLEM.SC8",0,&HD3FF,S
13 '
14 _XUNPACKS("VRAM-2  xv8",0)
15 BSAVE "VRAM-2.SC8",0,&HD3FF,S
16 SETPAGE1,1
17 BLOAD"VRAM-2MD.SC8",S
18 SETPAGE0,0
19 LINE(120,16)-(255,23),0,BF
20 LINE(0,24)-(151,31),0,BF
21 LINE(176,144)-(231,175),0,BF
22 COPY(0,0)-(255,211),1TO(0,0),0,TPSET
23 BSAVE "VRAM-2M.SC8",0,&HD3FF,S
```


## オリジナルの```"GAME.XB"```

(INIT.XBを実行してBASIC拡張してから実行する)

```
10 ' GAME (128K)
20 '
30 CLEAR 99,USR8(37)
40 ON STOP GOSUB 110:STOP ON
50 COLOR ,0,0:SCREEN 8,2
60 _XUNPACKS("TITLE   xv8",0)
70 _XUNPACKS("VRAM-2  xv8",1)
75 CLEAR 10,&H8400
80 BLOAD "DEMODATA.BIN"
90 BLOAD "PREPROG.BIN",R
100 _XCPU(&H80):BLOAD "PROG.OBJ",R
110 RETURN
```

## 書き換え版```"HYDLIDE.BAS"```

(INIT.XBのBASIC拡張を使用しない)

```
10 ' GAME (128K)
20 '
30 CLEAR 10,&H8400:DEFINT A-Z
40 COLOR,0,0:SCREEN 8,2
45 ON INTERVAL=60 GOSUB100:INTERVAL ON
50 SETPAGE,0:BLOAD"TITLE.SC8",S
60 SETPAGE,1:BLOAD"VRAM-2M.SC8",S
70 BLOAD "DEMODATA.BIN"
74 'SETPAGE,0:BLOAD"TITLEM.SC8",S
75 IF((C<10)AND(INKEY$=""))THEN 75
80 BLOAD "PREPROG.BIN",R
90 BLOAD "PROG.OBJ",R
100 C=C+1:RETURN
```

改変版タイトル画像も使いたい場合、  
お好みで74行の  
```
74 'SETPAGE,0:BLOAD"TITLEM.SC8",S
```
コメントアウトを解除してください。  
```
74 SETPAGE,0:BLOAD"TITLEM.SC8",S
```
