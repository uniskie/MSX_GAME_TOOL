﻿# HYDLIDE3 TOOL & KONAMI TOOL
 ハイドライド３、ガリウスの迷宮、パロディウス、F1-SPIRIT  
 対応の状態セーブロードツール（MSX実機向け）

DISK IMAGE -> [MEGA-UTL.dsk](MEGA-UTL.dsk)

## 変更履歴  
- 2025/04/13  
   - F1-SPIRIT向けのツールを追加
   - ソースファイルのメンテナンスと共通化
- 2025/04/06  
    - アセンブラソースコードのメンテナンス（ソースコードのリファクタやリネーム）
    - ツール類のメッセージを分かりやすく修正
    - PARODIUS.BAS、GALIOUS.BASでもニューゲームとコンティニューを区別
    - PARODIUSのEXTRA MENU→[C]でパワーアップをするように機能追加
- 2020/08/21  
    - HYDLIDE3.BASをFMPAC/PACに対応 セーブデータセーブロード時、  
      FMPAC/PACがあればそちらのSRAMを読み書きするように対応。  
    - HYD3CHAR.BASのバグ修正（アイテム選択で左カーソルが反応しない問題）  
- 2020/08/19  
    - HYD3CHAR.BASのバグ修正（マシン後書き込みアドレス計算がずれる問題）  
- 2020/08/10  
    - 初版  

---  
## ツールについて  
以下のゲームの状態保存・復帰などを出来るようにするツールです。  

- HYDLIDE3.BAS  
...「ハイドライドⅢ」補助ツール  

- PARODIUS.BAS  
...「パロディウス」補助ツール  

- F1SPIRIT.BAS  
...「F1-SPIRIT」補助ツール  

- GALIOUS.BAS  
...「ガリウスの迷宮」補助ツール  


処理乗っ取り系のツールなので、  
ROMカートリッジを挿さずに電源にBASICを起動し、  
各種BASICプログラムを実行後、  
該当ROMカートリッジを《後挿し》して使用します。  

（スロットは1か2で、拡張スロットも対応しています。）  

## その他ツール  

- HYD3CHAR.BAS  
...「ハイドライドⅢ」セーブデータ改造ツール  

- GAL-MUS.BAS  
...「ガリウスの迷宮」ミュージックボックス  
... ※SAVE-MUS.BASでROMイメージからの吸出しファイルを作成する必要がある  

- PARO-MUS.BAS  
...「パロディウス」ミュージックボックス  
...※SAVE-MUS.BASでROMイメージからの吸出しファイルを作成する必要がある  

- F1SP-MUS.BAS  
...「F1-SPIRIT」ミュージックボックス  
...※SAVE-MUS.BASでROMイメージからの吸出しファイルを作成する必要がある  

- SAVE-MUS.BAS  
...GAL-MUS.BAS / PARO-MUS.BAS用イメージファイル作成ツール  

## 再配布等  

ツール類の再配布や改造については特に制限はありません。  
使えると思った部分は流用していただいて構いません。  
（ソースコード類も同様です）  

ただし、何が起きても当方は責任は持ちません。  

---  
## ロムカートリッジの《後挿し》について  

PAUSEがある機種はを押した状態で挿すと比較的安全ですが、  
信号の状態によってはそれでもたまに暴走しますし、  
意図しない電流により破損の危険性があります。  

後挿しは危険なので、1CHIPMSXや似非メガROMの使用をお勧めします。  

- MGLOADやNSLOADはROMを読み込んで起動しないという指定が可能  
- 1CHIPMSXはスロットを内蔵似非RAMに切り替えるキーボードショートカットで  
- 一時的にスロットを無効化することが可能  

### 例）1chipMSX（OCM V3.8.0導入済みのもの）  

1. 電源を切った状態で、スロット１にハイドライド3を挿し電源ON  
1. MSXロゴ表示中に素早くSHIFT+F12を一回押す（素早く離す）  
    （スロット1が無効になって内蔵似非メガRAMに切り替わる）  
1. BASICまたはDOSプロンプトになったらSHIFT+F12を一回押す  
    （スロット1が有効に戻り、内蔵似非メガRAMが無効になる）  
（LEDランプが切り替わるのでそれで判断可能）  

---  
## 各プログラムの概要  

### HYDLIDE3.BAS  

ここでは概要のみ。  
詳細は [README_HYDLIDE3.MD](./README_HYDLIDE3.MD) 参照。  

- MSX1版/MSX2版両対応  
- MSX1/2/2+/turboR対応  
- MSX-DOS1/MSX-DOS2対応  
- 要：RAM64KB  

※ MSX1版ハイドライドⅢの場合はMSX1対応（※要RAM 64KB)  
※ MSX2版ハイドライドⅢの場合はMSX2以上（※要VRAM128KB）  
※ターボRの場合、ゲーム中は一時的にZ80に戻ります。  

- 拡張ポーズは[STOP]キーです。  

- 状態セーブ/ロードはBASICに戻って行います。  
    （常駐プログラムサイズの都合上）  

- 対応ROMロット: 光の剣、銀の剣両方で確認  

- MSX2版は1chipMSXのクロックアップ状態でしばらく動かしていると暴走します。  
    （このツールを使用していない場合でも同様です）

#### 操作例：キャラデータを改造して実行
1. RUN"HYDLIDE3.BAS
2. カートリッジ後挿し
3. LOAD CHARACTERSまたはPLAY→STOP→CTRL+@
4. CHARA DATA EDIT → CTRL+STOP→RUN"HYDLIDE3.BAS
5. SAVE CHARACTERS
6. LOAD CHARACTERS

※ SAVEした改造データはLOADで反映・PACにも保存

### PARODIUS.BAS & F1SPIRIT.BAS & GALIOUS.BAS  

ここでは概要のみ。  
詳細は [README_KONAMI.MD](./README_KONAMI.MD) 参照。  

- MSX2/2+/turboR対応  
- 要：RAM64KB/VRAM128KB  
- MSX1/2/2+/turboR対応  
- MSX-DOS1/MSX-DOS2対応  

※ VRAMに状態セーブするため、MSX2/VRAM128KB以上が必要です。  
※ MSX1には非対応です。  

■ 利用の目的  

- 新10倍が無くてもステートセーブロードできるようにするツールです。  

- MegaRAM+SDやCarnivore2があれば、Sofarunを利用して、  
1スロットでも新10倍＋ゲームの2本差しを再現実行できるので、  
それらがある人には不要です。  

---  
## ■【重要】新10倍と似非SD/SCSIを使う場合の注意 【ディスク破壊の可能性】  


MSX-DOS2カーネルを改造したSD/SCSI環境（1ChipMSXや似非SCSI環境）についての注意です。  

**【MSX-DOS2改造カーネル】ではなく、【Nextor】を利用してください。**  

でないとディスクアクセス時に  
（書き込みでなくても）ディスクを破壊する危険があります。  

例えば1ChipMSXデフォルトではNextorではなくMSX-DOS2+似非SDで動作するのですが、  
**SDカードを読みに行くだけで、SDカードを壊してしまう**確率が高いです。  

自分は何度もSDカードの中身が壊れて涙目になりました。  

OCM（1ChipMSX）に初期状態で組み込まれているSDカードドライバとの相性は特に悪い様子で、OCMでもNextorを使うと平気なようです。  

NextorのIDEドライバははMegaSDのものが使用できます。  
（OCMのSDBIOS機能を利用するなどして変更可能です）  

1ChipMSXではなく、MegaSDカートリッジの場合は  
普通、Nextorがプリインストールされているので、  
おそらくそのまま使っても大丈夫だと思います。  

（※ 他にも新10倍と相性の悪い組み合わせがあるかもしれません。）  

心配な場合は、新10倍ではなこちらの`PARODIUS.BAS`、`f1SPIRIT.BSA`、`GALIOUS.BAS`を使っていただければ、  
SDカード破壊の危険性が低くなります。  

---  
## ソースファイルについて  

srcフォルダにマシン後プログラムのソースが入っています。  
tniASM v0.45を使用してWindows上でクロスアセンブルしています。  
makeall.batで一括ビルド可能です。  

[tniASM v0.45 (2 November 2011, final freeware Z80/R800/GBZ80 version)](http://www.tni.nl/products/tniasm045.zip)
[tniASM - Macro Assembler home page](http://www.tni.nl/products/tniasm.html)

#### HYDLIDE3.BAS用  
- HYDLIDE3.ASM  
- HYD3-EXP.ASM  

#### 共用  
- EX-BIOS.ASM  

#### GALIOUS.BAS用  
- GALIOUS.ASM  
- GAL-EXPS.ASM  
- GAL-TITL.ASM  

#### F1SPIRIT.BAS用  
- F1SPIRIT.ASM  
- F1SP-EXP.ASM  
- F1SPPLAY.ASM  
- F1SPTITL.ASM  

#### PARODIUS.BAS用  
- PARODIUS.ASM  
- PARO-EXP.ASM  
- PAROPLAY.ASM  
- PAROTITL.ASM  

## おまけ  

#### 共用  
- BIOS-DEF.ASM ... BIOS系シンボル定義（使用しているもののみ）
- EX-BIOS.ASM ... 共用している処理まとめ
- KJ-VDP.ASM  ... screen5/7へ漢字表示  
- MOJI-24.ASM ... screen2/4へ文字表示  
- KONAMI8K.ASM ... KONAMI 8Kバンク/SCC向け定義
- BIOS-DEF.ASM ... BIOS関連のエントリやワークエリア定義

#### ガリウスの迷宮ミュージックボックス  
- GAL-MUS.BAS  
- GAL-MUS.BIN  
- GAL-MUS.OBJ (同梱無し)
  ... ROMバンク$00,$0D,$0Eをつなげたファイル  
- GAL-MUS.ASM  
- GMUS-SUB.ASM  
- GAL-TL-K.ASM  

#### F1-SPIRITミュージックボックス  
- F1SP-MUS.BAS  
- F1SP-MUS.BIN  
- F1SP-MUS.OBJ (同梱無し)
  ... ROMバンク$0D,$0E,$0Fをつなげたファイル  
- F1SP-MUS.ASM  

#### パロディウスミュージックボックス  
- PARO-MUS.BAS  
- PARO-MUS.BIN  
- PARO-MUS.OBJ (同梱無し)
  ... ROMバンク$00,$04,$05,$06,$0Aをつなげたファイル  
- PARO-MUS.ASM  

#### ミュージックボックス用ROMイメージ作成ツール  
（F1SP-MUS.OBJ/PARO-MUS.OBJ/GAL-MUS.OBJの作成）  
- SAVE-MUS.BAS  
- TFROM.BIN  
- TFROM.ASM  

