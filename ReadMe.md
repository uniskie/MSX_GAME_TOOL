****************************************************************
# The HOBBIT (MSX) Disk Loader set

MSX版THE HOBBITのカセットテープから
データを読み取り、ディスクに保存し、
実行するプログラムです。

- - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - - 
## 概要

ゲーム本体は解析しておらず、オリジナルの実行開始プロセスを解析し、
ディスクからロードするようにしたものになります。

1. オリジナルのローダーはタイマーフックを含めたフックテーブル周りを書き換えているのでそちらを再現（保険）

2. ゲーム本体をRAM$0000-$EFFFに転送した後で、ゲーム開始処理アドレスへジャンプ。

3. ゲーム開始処理実行アドレスを呼び出す際は割り込み禁止状態（基本）

****************************************************************
# 環境

- 要MSX2VRAM128KB/RAM64KB以上
- 要DISKドライブ
- 要カセットインターフェース+データレコーダ


****************************************************************
# テープ内のファイル構成

1.  HOBBIT ASCIIファイル(サイズ$28)...  BLOAD"CAS:HOBBIT"
2.  HOBBIT BSAVEファイル(サイズ$1A5)... 実行ファイル
3.  カスタムデータ0 (サイズ$1800)... タイトル画面キャラクタパターンデータ
4.  カスタムデータ1 (サイズ$1800)... タイトル画面キャラクタカラーデータ
5.  カスタムデータ2 (サイズ$74 ぐらい)... （忘れました）
6.  カスタムデータ3 (サイズ$1E00)... ゲーム本体1
7.  カスタムデータ4 (サイズ$1E00)... ゲーム本体2
8.  カスタムデータ5 (サイズ$1E00)... ゲーム本体3
9.  カスタムデータ6 (サイズ$1E00)... ゲーム本体4
10. カスタムデータ7 (サイズ$1E00)... ゲーム本体5
11. カスタムデータ8 (サイズ$1E00)... ゲーム本体6
12. カスタムデータ9 (サイズ$1E00)... ゲーム本体7
13. カスタムデータ10(サイズ$1E00)... ゲーム本体8

- タイトル画面は$1800サイズが2個。
- ゲーム本体は$1E00サイズが8個で合計で$F000。
- ローダーは$1A5サイズが一個。

- タイトル画面データの後の一つ目のバイナリはDISKローダーでは未使用
- BASICプログラムもDISKローダーでは未使用

> **Warning**  
>  HOBBIT.DATの作成手順やテープ内のファイルについては
>  手持ちの現物や20年前に作ったCASデータの状態が良くないため
>  検証が十分にできていません。
>
>  20年前当時作成したHOBBIT.DATやエミュレータでのCASファイル読み込み
>  実験などで記憶を頼りに書き起こした情報になります。

****************************************************************
# 使い方：準備

## ■ 【CASファイルの場合】

   https://github.com/uniskie/EXTRACT_MSX_CAS

   extract_cas.exeを使って中のファイルを取り出し、
   以後の結合作業を
   PC上のバイナリエディタで行う方が簡単かもしれません。

----------------------------------------------------------------
## ■ カセットテープ読み込みプログラムのロード

まずTAPE-IN.BASを実行します。

TAPE-IN.BASは`F1`キーにマシン語呼び出しをセットして
すぐBASICに戻ります。（`Ok`と表示されます）

テープを巻き戻し、テープの準備をします。


### ■ 余分なデータが付与されているケース
   実機だと問題はなかった気がするのですが、
   エミュレーターで実験した所、余計なデータがついていました。

<details>

<summary>
***余分なデータが付与されているケース：詳細***
（クリックで展開）
</summary>

   もし、テープロードした時に
   各ファイルの指定サイズより大きなアドレスが表示されていたら、
   その分余計なデータがついている可能性があります。

   その場合は
   テープ読み込み時に表示されたアドレスまで保存してから、
   PCのバイナリエディタなどで、
   余分な箇所を除去し、BSAVEヘッダのサイズ情報を修正します。

>	**Note**
>	結合作業もバイナリエディタで行うのであれば
>	BSAVEヘッダを除去してしまっても構いません。

   このテキストの後ろの方に、
   各ファイルの先頭ダンプデータを記載しましたので、参考にしてみてください。

>   **Warning**  私のデータが正しいとは限りません


   CASファイルを扱う場合、
   エミュレータで正常に動作するものであれば大丈夫だと思います。

-   例） BSAVEファイル

   先頭から&HD0が連続していたらCASファイルの余分なヘッダです。
   末尾に余計な0が複数個ついているケースもありました。

-  例） カスタムデータ
   
   先頭に0が一つ余計についていたり、
   末尾に余計な0が複数個ついているケースがありました。
</details>


----------------------------------------------------------------
## ■ 1. BASICプログラム → 読み捨て

`F1`キーを押してください。

```
a=user(0)
- ASCII -
FILENAME：HOBBIT
```

と表示された後、しばらく読み込み、

```
DATA:VRAM 10000H-10027H
Ok
```

と出て、BASICに戻ります。
（※正確なアドレスは記憶があやふやです）

これはテキスト形式のBASICプログラムなので無視します。

----------------------------------------------------------------
## ■ 2. ローダープログラム → あとで合成

続けて`F1`キーを押してください。

```
a=user(0)
- BLOAD -
FILENAME：HOBBIT
```

と表示された後、しばらく読み込み、

```
HEAD:FD09H
 END:FEADH
  GO:FD09H
DATA:VRAM 10000H-1????H
Ok
```

と出て、BASICに戻ります。

これは先ほどのHOBBITというBASICプログラムから読み込まれる
マシン語プログラムで、ローダー部分に相当します。

こちらは後で使用するので、ディスクに保存します。

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBITLD.BIN",0,&H01A4,S
```

と、一気に入力してリターンキーを押してください。

* HOBBITLD.BIN は実際には使わないのですが、念のためという感じです。


----------------------------------------------------------------
## ■ 3. 画面データ（パターン）→ あとで結合

続けて`F1`キーを押してください。

```
a=user(0)
- OTHER DATA -
```

と表示された後、かなり長い間読み込み、

```
DATA:VRAM 10000H-17FFH
Ok
```

と表示されます。

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBITG.BIN",0,&H17FF,S
```

と、一気に入力してリターンキーを押してください。


----------------------------------------------------------------
## ■ 4. 画面データ（カラー）→あとで結合

続けて`F1`キーを押してください。

```
a=user(0)
- OTHER DATA -
```

と表示された後、かなり長い間読み込み、

```
DATA:VRAM 10000H-17FFH
Ok
```

と表示されます。

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBITC.BIN",0,&H17FF,S
```

と、一気に入力してリターンキーを押してください。

----------------------------------------------------------------
## ■ 5. 本体ロードプログラム？ → 読み捨て

続けて`F1`キーを押してください。

```
a=user(0)
- OTHER DATA -
```

と表示された後、かなり長い間読み込み、

```
DATA:VRAM 10000H-1????H
Ok
```

と表示されます。
（????の所は$100以下だと思います。）

使用しませんが、念のため

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT0.BIN",0,&H1????,S
```

として保存します。

* サイズが7.5KByte($10000-$11FFF)の場合は、ゲームデータ本体なので
  次項の手順に従ってBSAVEしてください。


----------------------------------------------------------------
## ■ 6.- 13.ゲーム本体（8KB x 8個）→ あとで合成

続けて`F1`キーを押してください。

```
a=user(0)
- OTHER DATA -
```

と表示された後、かなり長い間読み込み、

```
DATA:VRAM 10000H-11DFFH
Ok
```

と表示されます。

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT1.BIN",0,&H1DFF,S
```

と、一気に入力してリターンキーを押してください。

同じ手順を合計8回行い、

```
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT2.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT3.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT4.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT5.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT6.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT7.BIN",0,&H1DFF,S
SCREEN5:SETPAGE2,2:BSAVE"HOBBIT8.BIN",0,&H1DFF,S
```

まで保存します。

****************************************************************
# HOBBIT.DATの生成

すべてのデータを保存したら、
先ほど保存したデータを結合していきます。

結合するデータは

1.  HOBBITG.BIN  (サイズ$1800)... タイトル画面キャラクタパターンデータ
2.  HOBBITC.BIN  (サイズ$1800)... タイトル画面キャラクタカラーデータ
3.  HOBBIT1.BIN  (サイズ$1E00)... ゲーム本体1
4.  HOBBIT2.BIN  (サイズ$1E00)... ゲーム本体2
5.  HOBBIT3.BIN  (サイズ$1E00)... ゲーム本体3
6.  HOBBIT4.BIN  (サイズ$1E00)... ゲーム本体4
7.  HOBBIT5.BIN  (サイズ$1E00)... ゲーム本体5
8.  HOBBIT6.BIN  (サイズ$1E00)... ゲーム本体6
9.  HOBBIT7.BIN  (サイズ$1E00)... ゲーム本体7
10. HOBBIT8.BIN  (サイズ$1E00)... ゲーム本体8
11. HOBBITLD.BIN (サイズ$1A5)... 実行ファイル

の順番で結合し、HOBBIT.DAT とファイル名を付けて保存します。

(HOBBIT0.BIN は使いません)

MSX上で行う場合は、64KBを超えるのでVRAMでの作業でも少し面倒です。
PCのバイナリエディタで行うのが簡単だと思います。

> **Note**  
>
>  【バイナリエディタを使用する場合の注意】
>   BSAVEファイルなので、先頭に7バイトのヘッダが余分についています。
>   バイナリエディタで結合する場合はヘッダを除去してから結合してください。

> **Note**  
>
>    HOBBITLD.BIN は実際には使わないのですが、念のためという感じです。

****************************************************************
参考：各バイナリの先頭データ

* アドレスは HOBBIT.DAT 上での位置

1.  HOBBITG.BIN  (サイズ$1800)... タイトル画面キャラクタパターンデータ
	```
	00000: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00020: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00030: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00040: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00050: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	00060: 00 00 00 00 00 00 00 00 00 00 00 00 01 01 01 01
	00070: 01 07 1E 78 E1 87 06 64 98 B4 E4 C4 E4 A5 27 26
	```

2.  HOBBITC.BIN  (サイズ$1800)... タイトル画面キャラクタカラーデータ
	```
	01800: 1F 1F 1F 1F 1F 1F 1F 1F 1D 1D 1D 1D 1D 1D 1D 1D
	01810: 1D 1D 1D 1D 1D AD AD AD 1D 1D 1D 1D 1D 1D 1D 1D
	01820: 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D 1D
	01830: 1D 1D 1D 1D 1D 1D 1D 1D 1F 1F 1F 1F 1F 1F 1F 1F
	01840: FF 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F
	01850: 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F
	01860: 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F FF 1F 1F 1F 1F
	01870: 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F 1F
	```

3.  HOBBIT1.BIN  (サイズ$1E00)... ゲーム本体1
	```
	03000: 8D 00 8D 00 00 00 00 00 00 00 00 00 00 00 00 00
	03010: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	03020: 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00 00
	03030: 00 00 00 00 00 00 00 00 C9 00 00 00 00 00 00 00
	03040: 22 0A 04 C3 0A 04 04 04 04 CC 64 A3 C8 25 C2 D6
	03050: 5D 85 59 1F 2E 48 CC 4E D6 FD EE AE 01 42 1D ED
	03060: 46 1D AC 44 14 61 D6 A4 E4 D6 A4 E4 DA 84 C4 CE
	03070: F5 E1 DE 90 18 A4 82 E1 0E 44 20 14 42 48 16 01
	```

4.  HOBBIT2.BIN  (サイズ$1E00)... ゲーム本体2
	```
	04E00: 08 C8 24 23 34 92 15 45 8A 3A 1B 3B A7 B9 22 C5
	04E10: 91 62 FE EE E8 B5 E9 21 79 AE 05 17 FE 16 B5 D8
	04E20: AA EC 5D 76 2E BB 14 45 96 70 AB 08 55 84 2A 8C
	04E30: 5D EF D3 5F 23 03 49 C1 A4 E0 D2 70 49 31 44 58
	04E40: BA CE FA A8 8B B1 45 DD 6A 0A E8 55 76 5E 66 B3
	04E50: 06 5C 51 22 41 16 70 CB 8A 24 49 12 5E 84 B9 2D
	04E60: 4D 5C D6 AA 2E 85 54 A3 2E EB 91 15 C8 8A E4 45
	04E70: 72 22 B9 11 5C 88 AE 44 57 22 2B 91 15 C8 8A E4
	```

5.  HOBBIT3.BIN  (サイズ$1E00)... ゲーム本体3
	```
	06C00: F2 74 46 46 5E FF 12 5E 44 22 42 3F 10 EF 49 00
	06C10: 0E A8 61 DC 99 5C 54 45 79 57 0D D4 4E 9B FC 45
	06C20: A8 CF D0 91 20 80 B8 08 E3 A7 A1 83 5E C5 EC F3
	06C30: D4 34 63 DB 3C 25 5C 11 8E 5C 11 7E 5C 11 6E 5C
	06C40: 11 5E 5E 14 63 22 E8 D0 11 4C 44 10 4D 60 84 68
	06C50: 44 84 C4 A8 58 84 BC F2 00 1D 68 97 10 89 49 15
	06C60: 19 58 96 99 34 99 43 03 AE 78 75 4A 2A 46 A2 A5
	06C70: 4D 5C 10 EB 82 1D 50 D5 36 CB 18 44 D1 24 F5 8A
	```

6.  HOBBIT4.BIN  (サイズ$1E00)... ゲーム本体4
	```
	08A00: AB DD C0 77 5C 52 38 37 52 3D EE 8C 7A 25 80 13
	08A10: 6D 64 B8 07 6B E1 52 1D CF 1C 90 89 96 12 17 E6
	08A20: 75 4D F5 A0 24 2C BD 11 09 08 77 25 AD 69 B0 02
	08A30: EA B5 80 A3 20 A6 46 E5 E1 FA EE 2B C9 11 80 F0
	08A40: 95 04 E3 15 A0 1C 75 3D 48 B5 CB C3 D1 16 24 02
	08A50: 54 A4 39 54 8B 15 0F 21 E1 24 2E 88 4B C0 7A AD
	08A60: 58 87 22 A1 2D C8 4A 09 DA 04 5C 91 0A 41 42 48
	08A70: 6C 4B 84 3D 70 A8 16 EC 28 84 11 10 82 21 15 C2
	```

7.  HOBBIT5.BIN  (サイズ$1E00)... ゲーム本体5
	```
	0A800: 00 0B 0A 00 0D 09 00 0E FF 04 FF 41 06 27 02 7B
	0A810: 08 00 00 09 00 0C FF 04 FF 41 06 27 02 7B 08 00
	0A820: 00 0A 00 0C 07 00 0F 02 00 18 08 00 1B FF 04 FF
	0A830: 41 06 27 02 7B 08 00 00 02 00 1B 05 00 0E 08 00
	0A840: 15 04 00 14 FF 04 FF 41 06 27 02 7B 08 00 00 08
	0A850: 00 14 FF 04 FF 41 06 27 02 7B 08 00 00 09 00 1A
	0A860: 04 00 19 01 00 12 FF 04 FF 41 06 27 02 7B 08 00
	0A870: 00 07 00 16 03 00 0B 02 00 11 09 00 13 FF 04 FF
	```

8.  HOBBIT6.BIN  (サイズ$1E00)... ゲーム本体6
	```
	0C600: D7 8C E6 8C A3 8C 14 D0 7F 8C 3D 8C C7 93 9F 8C
	0C610: CD 8C D5 8F FF 8C 2B 8D 2F 8E 48 91 99 8B AA 91
	0C620: 61 90 C3 D1 7B 90 51 8B 5D D4 4C 93 C1 8E B8 D4
	0C630: 3D 8F 04 D3 1E 94 97 8C 95 8B C4 90 A1 90 E4 8A
	0C640: D2 91 B7 8D 00 F3 3E FF 32 64 86 CD 6F BE F3 31
	0C650: 00 60 CD 83 BE CD EB 97 3E 80 CD 63 C8 CD 46 86
	0C660: CB 7F 28 F4 E6 7F FE 4E 3E 00 28 01 3C 32 65 86
	0C670: 06 F0 21 B0 86 CD 4D B4 AF 32 D8 BE 32 D9 BE 32
	```

9.  HOBBIT7.BIN  (サイズ$1E00)... ゲーム本体7
	```
	0E400: FB F1 32 C4 BE C3 31 B3 C3 4C 86 DD E5 F5 2A 23
	0E410: 86 7C B5 28 26 E5 DD E1 21 00 00 3A 65 86 A7 28
	0E420: 17 F1 F5 CD 6D C9 21 00 00 FE FF 28 0B DD 6E 01
	0E430: DD 66 02 ED 5B 23 86 19 CD 25 86 F1 DD E1 C9 F5
	0E440: 3E 0D CD 08 B4 F1 C9 00 00 00 00 00 00 AF 77 23
	0E450: 10 FC C9 3D 6F 26 00 29 29 29 CD 13 BE 19 C9 DD
	0E460: 7E 05 0F 0F 0F 0F E6 0F 4F DD 7E 07 E6 F0 81 32
	0E470: DC BE DD 7E 01 0F 0F 0F 0F E6 0F 4F DD 7E 03 E6
	```

10. HOBBIT8.BIN  (サイズ$1E00)... ゲーム本体8
	```
	10200: 5D D2 47 CD F4 C8 DD 2A C5 BE DD 7E 06 CD 5D D2
	10210: B8 D2 F0 BD 4F C6 10 30 02 3E FF B8 38 2D 78 91
	10220: 3D 07 5F 16 00 FD 21 78 94 FD 19 FD 6E 00 FD 66
	10230: 01 0F 0F 47 2F DD 86 05 30 03 DD 77 05 78 0F 2F
	10240: DD 86 06 30 03 DD 77 06 C3 34 B6 CD F5 BD DD CB
	10250: 07 DE 3A C2 BE CD 94 C3 3E 06 C3 10 CD C5 47 3E
	10260: 0A CD 63 C8 4F 80 30 06 AF CB 79 20 01 3D C1 C9
	10270: DD 2A C5 BE DD 7E 00 3D C9 CD BF CD DD 2A C5 BE
	```

11. HOBBITLD.BIN (サイズ$1A5)... 実行ファイル
	```
	12000: 00 3E 08 D3 AB 3E 0E D3 A0 21 57 04 51 CD 77 FD
	12010: D8 79 FE DE 30 F3 FE 05 38 EF 92 30 02 ED 44 FE
	12020: 04 30 E6 2B 7D B4 20 E4 21 00 00 45 55 CD 77 FD
	12030: D8 09 15 20 F8 01 AE 06 09 7C CB 1F E6 7F 57 29
	12040: 7C 92 57 D6 06 32 09 FD 7A 87 06 00 D6 03 04 30
	12050: FB 78 D6 03 32 0A FD B7 C9 CD 63 FE 0E 00 0C 28
	12060: 0A DB A2 AB F2 68 FD 7B 2F 5F C9 0D C9 CD 63 FE
	12070: DB A2 CB 07 38 F7 1E 00 CD 66 FD C3 68 FD 3A 0A
	```
	（* この HOBBITLD.BIN は 多分壊れてるが、使わないので問題ない）


****************************************************************
# 使い方：実行

HOBBIT.DATが準備できたら
```
RUN"HOBBIT.BAS"
```
を実行するだけです。

タイトル画面の出方も、テープオリジナルと近いように再現しています。

>	**Warning**  
>	ただし、セーブデータの保存と読み込みはテープが必要です。

キーマトリクスをゲームでは直接読み込んでいるので、
ハックして割り込んで何か特殊な処理でBASICに戻るなどの改造が
当時の自分では出来ませんでした。


****************************************************************
# ファイル説明

- HOBBIT.ASM	... 	ローダーのアセンブラソースコード
			（一部ロストしたため逆アセンブルからの復元）
- FILEIN.ASM	... 	HOBBIT.ASM から使用

- HOBBIT.BIN	... 	ローダーの実行バイナリ。HOBBIT.BASから使用

- HOBBIT.BAS	... 	HOBBIT.DATを読み込んで実行

- TAPE-IN.ASM	... 	テープからVRAMに読み込む処理のソースコード

- TAPE-IN.BIN	... 	テープからVRAMに読み込む処理のバイナリファイル

- TAPE-IN.BAS	... 	テープからVRAMに読み込むプログラムをセットする

- FILEADRS.BAS	... 	BSAVEされたファイルのヘッダを読み込んで
			先頭アドレスや終了アドレスを表示


