
# トリトーン(テープ版)をディスクから実行するツールセット

- ※要：RAM64KB
- ※ゲーム状態のセーブ・ロードはカセットテープが必要
- ※（カセットテープが使えない場合は、メモリセーブ・ロードで頑張る）

ディスクイメージ: [TRITON_T.dsk](TRITON_T.dsk)

[SourceFiles](https://github.com/uniskie/MSX_GAME_TOOL/tree/main/TRITON_TAPE2DSK/SRC/)

## セット内容

- [TRITON.BAS](SRC/TRITON.BAS)	...BASIC上からローダーを実行する
- [TRITREAD.BIN](SRC/TRITREAD.BIN) ...TRITON.BASで使用するマシン語バイナリ

- [extract_cas.exe](extract_cas.exe) ... CASファイルから個別のファイルを取り出すツール

### ソースファイル
- [TRITREAD.ASM](SRC/TRITREAD.ASM) ...マシン語部分ソースファイル（メイン）
- [FILEIO.ASM](SRC/FILEIO.ASM) ...マシン語部分ソースファイル（ファイルアクセス系）
- [CHGSLT.ASM](SRC/CHGSLT.ASM) ...マシン語部分ソースファイル（スロット変更：ページ0切り替えのため）

### おまけ
- [TRIREAD_v0.ASM](SRC/TRIREAD_v0.ASM) ... 旧版（遅い）：マシン語部分ソースファイル（メイン）
- [TRIOLD.BAS](SRC/TRIOLD.BAS) ... 旧版（遅い）：BASICからローダーを実行する
- [TRIOLD.BIN](SRC/TRIOLD.BIN) ...旧版（遅い）：TRITON.BASで使用するマシン語バイナリ

## データの準備

1. テープの音をWAVファイルに保存
2. **なんでもピーガー**か**MSX CasTools**でWAVファイルからCASファイルに変換
3. `extract_cas.exe`でCASファイルの中身を取り出す
   	（`TRITON.BIN`、`custom_0.DAT`が取り出せる）
4. `custom_0.DAT`を`GAMEDATA.DAT`にリネーム
5. `TRITON.BAS`、`TRITREAD.BIN`、`TRITON.BIN`、`GAMEDATA.DAT`をディスク（イメージ）に保存

## 使い方

MSX DISK BASIC上から

```basic
RUN"TRITON.BAS"
```

## 懸念事項

8000hから8620hあたりをローダープログラム（BASIC+マシン語）で使用しているため、
トリトーンテープ版がその範囲が00やFFhでクリアされていることを期待した処理だった場合に、何処かで問題が出るかもしれません。

ROM版にはMSX2以降だとラスボスで停止するバグがあるので、少し心配です。  
<https://www.msx.org/ja/news/software/ja/tritorn-fix-rom-torito-n-bagu-patuti>  
→ ”具体的にはE453hの内容の下一桁がFhだとエラーが起きるようです。”

## その他

マシン語ファイルは、tniASMで、TRITREAD.ASMをアセンブルしています。  
<http://www.tni.nl/products/tniasm.html>

extract_cas.exeのソースファイルはこちらです。  
<https://github.com/uniskie/EXTRACT_MSX_CAS>

## その他解説

マシン語部分は、
1. GAMEDATA.DATをディスクから読み込みRAMの2000h～7FFFhへ転送し
2. TRITON.BINの最後のテープリード処理を書き換えて
3. RAMの2000h～7FFFhに読み込み済みのGAMEDATA.DATを8800hへ転送&実行します。

この時、スロットページ0（0000h～3FFFhの空間）をスロット切り替えしますが、
BIOSのENASLTはページ0にあるのでページ0のスロットを切り替えた瞬間に暴走します。

そのため、ENASLTと同等の処理を自前で用意して、
ページ2にスロット切り替えプログラムを配置実行しています。
(CHGSLT.ASMがENASLTクローンコードになります)

（※注：拡張スロットを操作する際、ページ3を一時的に切り替えるため、ページ3にスロット切り替えプログラムを配置した場合も暴走します）

## おまけについて

ENASLT（の同等処理）でスロット切り替えして一気に転送するのではなく、
1バイトずつWRSLT/RDSLTで転送する実験バージョンです。

非常に遅いので、なんとなくテープ版の気分が味わえます。

（※注：WRSLT/RDSLTはページ0をアクセスしても問題ありませんので楽ですがとても遅いです）


# トリトーン テープ版 解析

ざっくりした解析情報

## BIN部分(BLOAD"CAS:",R)

$A000～$DAFF、開始$A000

- $A100から$A3D6までの$2D7bytesを$E900へコピー
- （$A00E～$A0FFが空き領域）
- （$A3AF～$A3D6がプログラム転送対象の空き領域）
- （$A3D7～$A3FFが空き領域）
- （$A400～$AFFFも空き領域？）
- （$B000～がVRAM用データ）
- （$DB00～$E8FFが未使用空き領域）
- $E900にジャンプ
- SPを$87FFに設定
- VRAMへデータ転送
- $EB0D：テープからカスタムデータ部分をリードして実行
	(元は$A30D～$A3AE)

転送されるのは$A3D6までなので、
テープリード処理の書き換えは、200bytesまでなら可能。
（オリジナルは162bytes）

## データ部分

- +$0000：識別ヘッダ "KAJI.." 4B 41 4A 49 2E 2E
- +$0006：$6000byte → $8800～$E7FFへ転送後、$8800から実行
- +$6006：これ以降は余計なデータ。読み込まれない。

## 参考

- フリーエリア HIMEM(FC4AH)
- MSX：仮想1ドライブ：$E47D
- MSX：仮想2ドライブ：$DE67
