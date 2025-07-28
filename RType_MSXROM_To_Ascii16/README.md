
# R-Type ROMパッチ

WINIPSなどを使用してROMイメージにパッチを当ててください。

パッチを当てると>エミュレーターは自動でRTypeマッパーを認識しない可能性がありますので、その場合は手動でRTYPEマッパーを指定してください。

似非RAMなどで使用する場合は、ASCII16Kバンク化ツールを使用してください。

（※ このパッチはASCII16Kバンク化前に使用してください）


1. FM音源版の音量を+3する  
    [RTYPE_BGM_VOLUME_UP.ips](RTYPE_BGM_VOLUME_UP.ips)

2. FM音源版の音量を+3する & 本体内蔵(FMPAC不要)で鳴るようにする  
    [RTYPE_BGM_VOLUME_UP_AND_PACFIX.ips](RTYPE_BGM_VOLUME_UP_AND_PACFIX.ips)

> OPLL認識バグ修正についての詳細
> https://www.tiny-yarou.com/kaizoumsx_rtype.html

# BGM音量修正

元の音量だと効果音が大きすぎるので、BGM音量を上げて対処しています。

楽曲データを一通り解析した感じ、ゲームオーバー時のバイオリンがV15でそれを基準に他を下げたような印象です。

効果音の音量を下げたほうが良いのかもしれませんが、効果音データは解析できてないのでBGM音量を上げて対処しました。

そのためゲームオーバー時などのバイオリンの音が元より（相対的に）少し小さいという問題があります。

- 参考：BGM解析情報  
  https://github.com/uniskie/msx_music_data/blob/master/doc/RTYPE_memo.md

# RType_MSXROM_To_Ascii16  
  
■ R-Typeの特殊ROMバンクを変更してASCII 16KBバンクに変更するツール  
  
「[rtype_to_ascii16.exe](rtype_to_ascii16.exe)」 .... アールタイプをASCII16化するツール  
  
R-TypeのROMは特殊なバンクであるため、対応しないエミュレータがあります。  
またMegaFlashROM/MegaRAM/Carvonire2などでもそのままでは動作しません。  
そこで、  
ASCII16KタイプのROMとして動作するようにROMイメージを書き換えるツール  
を作りました。  
  
## ツールの使い方：  
  
[rtype_to_ascii16.exe](rtype_to_ascii16.exe)  に、  
R-TypeのROMファイルをドロップしてください。  
すると、`元ファイル名+_ASCII16.ROM`というファイルが出来ます。  
  
## 対象ROM：  
  
検証したROMは、  
`MGSAVE.COM`で作成したイメージファイルです。  
  
サイズ:512KByte  
MD5: 99BC435A1E7885F02B28B7FE94AB2499  
SHA1:37BD4680A36C3A1A078E2BC47B631D858D9296B8  
  
注：384Kbyteにトリミングしたファイルは対象外です。  
   （作成されたROMを実行すると6面でフリーズします）  
  
## 作成されたROMイメージについて：  
  
作成された`*_ACII16.ROM`ファイルはASCII16タイプで動作します。  
  
エミュレータではMegaROM Bank Typeを認識しないので  
手動で ASCII 16KB Bank を指定してください。  
  
  
## ほかのパッチを当てたい場合：  
  
FM音源認識修正パッチなどは、  
このツールで書き換える 前 に適用してください。  
  
[rtype_to_ascii16.exe](rtype_to_ascii16.exe) で書き換えてしまうと  
バンクの配置も変更するのでアドレスが変更されます。  
そのため、他のパッチが正常に当てられなくなります。  
  
おまけ：  
-	[rtype_fmfix_code.asm](src/rtype_fmfix_code.asm)  
	... 変更部分のソースファイル（TNIASM等でアセンブル）  
  
-	[rtype_org.txt](src/rtype_org.txt)  
	... 変更前の該当箇所の逆アセンブルリスト（実行時アドレス付き）  
  
-	[rtype_fmfix.txt](src/rtype_fmfix.txt)  
	... 変更後の該当箇所の逆アセンブルリスト（実行時アドレス付き）  
	（イメージファイルの3C2A2h、5C2A2h2か所を置き換えます）  
	（MSX-MUSIC検出パッチはASCII16化ツールとは分けています。）  
  
## 参考：  
  
MSX.ORGのスレッド  
Home » Forum » MSX Talk » Software » R-Type and Mega Flash ROM  
https://www.msx.org/forum/msx-talk/software-and-gaming/r-type-and-mega-flash-rom  
  
れふてぃさんのサイト（MSX-MUSIC検出バグ）  
http://www7b.biglobe.ne.jp/~leftyserve/delusion/del_rtyp.htm  
  
## どういう作業をしているの？  
  
[src/rtype_to_ascii16.py](src/rtype_to_ascii16.py)（ソースファイルテキスト）  
をお読みください。  
  
特殊なバンク構成で  
- 前半2MBit：16KByte単位のバンク  
- 後半1MBit：8KByte単位のバンク  
  
となっています。  
  
これ自体はMGSAVE.COMなどでASCII16としてファイルに取り込む分には問題ありませんが、  
問題は、  
  
「**電源投入時の初期状態がバンク0ではない**」  
  
事です。  
  
（実機ROMでは、電源投入時はバンク15（ROMイメージ3C000H）が初期選択されています。）  
  
ですので、書き換え作業としては  
  
| ROMイメージアドレス | 内容 |  
|--|--|  
| 00000h|バンク15（元ROMイメージ3C000H）|  
| 04000h|バンク0（元ROMイメージ00000H）|  
| 08000h|バンク1（元ROMイメージ04000H）|  
  
とし、  
以下、同様にバンクを1つずつずらすようにします。  
  
 (※バンク番号は16kByteバンクとしての番号です)  
  
また、バンクが後ろに１つずつずれますので  
バンク切り替えを行っているコード  
  
	LD (7000H),A  
  
を  
  
	CALL 4004H  
  
に書き換え、  
  
4004Hは  
  
	PUSH AF  
	INC A  
	LD (7000H),A  
	POP AF  
	RET  
  
というコードに置きかえています。  
  
もっと難しい説明があったのですが、  
これで動いたので、そういう感じで。  
  
## 修正履歴：  
- v2...512kByte全域を加工するように修正。（384Kbyte出力では停止してしまう問題の修正）  
- v1...とりあえず作成。  
  