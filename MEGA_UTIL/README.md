# HYDLIDE3 TOOL & KONAMI TOOL
 ハイドライド３、ガリウスの迷宮、パロディウス、F1-SPIRIT  
 対応の状態セーブロードツール（MSX実機向け）

DISK IMAGE -> [MEGA-UTL.dsk](MEGA-UTL.dsk)

## 変更履歴  
- 2025/04/25  
   - KONAMI.BASでゲームが起動しなくなった問題の修正(KONASERCH.ASM)
- 2025/04/24 -2  
   - ガリウスの迷宮をSCCカートリッジと誤認する問題を修正（PARO-MUS,F1SP-MUS）
- 2025/04/24  
   - SCCの自動認識を追加（PARO-MUS,F1SP-MUS）
- 2025/04/23  
   - アセンブラをAILZ80ASMに変更  
     （なるべく共通モジュールにしたいので順次リファクタリング中）
   - KONAMI.BASの対応ソフトを強化  
     (わんぱくアスレチックの動作安定化。  
     　コナミのゴルフをリストに追加。等）
   - 沙羅曼蛇は要RAM16KBのソフトなので対応から除外
   - PARO-MUS、F1SP-MUSのSCCスロット指定が機能しなくなっていたのを修正
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

- KONAMI.BAS  
  ...コナミ後期MSX1ソフト汎用クイックセーブロードツール  

処理乗っ取り系のツールなので、  
ROMカートリッジを挿さずに電源にBASICを起動し、  
各種BASICプログラムを実行後、  
該当ROMカートリッジを《後挿し》して使用します。  

（スロットは1か2で、拡張スロットも対応しています。）  

## その他ツール  

- HYD3CHAR.BAS  
  ...「ハイドライドⅢ」セーブデータ改造ツール  

- GAL-MUS.BAS  
  ...「ガリウスの迷宮」JUKE-BOX (サウンドテスト)  
  ... ※SAVE-MUS.BASでゲームROMからGAL-MUS.OBJを作成しておく必要があります。

- PARO-MUS.BAS  
  ...「パロディウス」JUKE-BOX (サウンドテスト)  
  ... ※SAVE-MUS.BASでゲームROMからPARO-MUS.OBJを作成しておく必要があります。

- F1SP-MUS.BAS  
  ...「F1-SPIRIT」JUKE-BOX (サウンドテスト)  
  ... ※SAVE-MUS.BASでゲームROMからF1SP-MUS.OBJを作成しておく必要があります。

- SAVE-MUS.BAS  
  ... ROMからJUKE-BOX用バイナリファイル作成を作成するツール  
  ... 「ガリウスの迷宮」「パロディウス」「F1-SPIRIT」用

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

## HYDLIDE3.BAS  

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

### 操作例：キャラデータを改造して実行
1. RUN"HYDLIDE3.BAS
2. カートリッジ後挿し
3. LOAD CHARACTERSまたはPLAY→STOP→CTRL+@
4. CHARA DATA EDIT → CTRL+STOP→RUN"HYDLIDE3.BAS
5. SAVE CHARACTERS
6. LOAD CHARACTERS

※ SAVEした改造データはLOADで反映・PACにも保存

---  

## PARODIUS.BAS / F1SPIRIT.BAS / GALIOUS.BAS / KONAMI.BAS  

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

## おまけ：独立動作版 JUKE-BOX  

- GAL-MUS.BAS  
- PARO-MUS.BAS  
- F1SP-MUS.BAS  

`SAVE-MUS.BAS`でロムカートリッジから必要なデータを取り出したOBJファイルを作成しておきます。

OBJファイルを利用して（ロムカートリッジなしで）JUKE-BOXを実行するプログラムです。
（SCC音源を使う場合はSCCカートリッジを挿す必要があります。）

### JUKE-BOX対応ROM

```
Bytes   SHA1                                     Name
------- ---------------------------------------- ------------
131,072 42FBB18722DF3E34E5B0F935A2DC0CE0D85099E9 F1SPIRIT.ROM
131,072 4D51D3C5036311392B173A576BC7D91DC9FED6CB GALIOUS.ROM
131,072 2220363AE56EF707AB2471FCDB36F4816AD1D32C PARODIUS.ROM
-------------------------------------------------------------
```

### JUKE-BOX (サウンドテスト) 用 ROMイメージ作成ツール  
（F1SP-MUS.OBJ/PARO-MUS.OBJ/GAL-MUS.OBJの作成）  
- SAVE-MUS.BAS  ... ゲームROMからファイルを作成  
- TFROM.BIN     ... 機械語プログラム  

### ガリウスの迷宮 JUKE-BOX (サウンドテスト)  
- GAL-MUS.BAS ... JUKE-BOX起動  
- GAL-MUS.BIN ... 機械語プログラム  
- GAL-MUS.OBJ ... (同梱無し/SAVE-MUS.BASで作成)  
              ... ROMバンク$00,$0D,$0Eをつなげたファイル  

### F-1スピリット JUKE-BOX (サウンドテスト)  
- F1SP-MUS.BAS ... JUKE-BOX起動  
- F1SP-MUS.BIN ... 機械語プログラム  
- F1SP-MUS.OBJ ... (同梱無し/SAVE-MUS.BASで作成)  
               ... ROMバンク$0D,$0E,$0Fをつなげたファイル  

### パロディウス JUKE-BOX (サウンドテスト)  
- PARO-MUS.BAS ... JUKE-BOX起動  
- PARO-MUS.BIN ... 機械語プログラム  
- PARO-MUS.OBJ ... (同梱無し/SAVE-MUS.BASで作成)  
               ... ROMバンク$00,$04,$05,$06,$0Aをつなげたファイル  

---  

## ソースファイル

srcフォルダにマシン後プログラムのソースが入っています。  
AILZ80ASMを使用してWindows上でクロスアセンブルしています。  
（使用アセンブラをTNIASMからAILZ80ASMに変更しました。）  
MAKEALL.BATで一括ビルド可能です。  

[AILZ80ASM](https://github.com/AILight/AILZ80ASM)

### 共用  
- BIOS-DEF.ASM ... BIOS系シンボル定義（使用しているもののみ）  
- EX-BIOS.ASM ... 共用している処理まとめ  
- CHGSLT.ASM  ... スロット処理まとめ  
- KJ-VDP.ASM  ... screen5/7へ漢字表示  
- MOJI-24.ASM ... screen2/4へ文字表示  
- KONAMI8K.ASM ... KONAMI 8Kバンク/SCC/コナミゲームID取得  
- BIOS-DEF.ASM ... BIOS関連のエントリやワークエリア定義  
- PAC-TOOL.ASM ... Pana Amusement Cartridge関連
- KONAMI8K.ASM ... コナミ共通（ROMバンクやSCC関連）

### HYDLIDE3.BAS用  
- HYDLIDE3.ASM  ... 起動処理
- HYD3-EXP.ASM  ... 拡張ポーズ処理
- HYD3CHAR.BAS  ... キャラクターデータ改造ツール

### GALIOUS.BAS用  
- GALIOUS.ASM  ... 起動処理  
- GAL-EXPS.ASM ... 拡張ポーズ・クイックセーブロード処理  
- GAL-PLAY.ASM ... JUKE-BOX処理  
- GAL-PL-D.ASM ... JUKE-BOX表示処理  
- GAL-TITL.ASM ... 曲名リスト  

### F1SPIRIT.BAS用  
- F1SPIRIT.ASM ... 起動処理  
- F1SP-EXP.ASM ... 拡張ポーズ・クイックセーブロード処理  
- F1SPPLAY.ASM ... JUKE-BOX処理  
- F1SPTITL.ASM ... 曲名リスト  

### PARODIUS.BAS用  
- PARODIUS.ASM ... 起動処理  
- PARO-EXP.ASM ... 拡張ポーズ・クイックセーブロード処理  
- PAROPLAY.ASM ... JUKE-BOX処理  
- PAROTITL.ASM ... 曲名リスト  

### KONAMI.BAS用  
- KONAMI.ASM   ... 起動処理  
- KONA-EXP.ASM ... 拡張ポーズ・クイックセーブロード処理  
- KONASRCH.ASM ... 汎用対応向け処理  
- KONALIST.ASM ... コナミゲームID、タイトル名リスト  

### F1SP-MUS.BAS用
- F1SP-MUS.ASM ... JUKE-BOX起動  
- F1SPPLAY.ASM ... JUKE-BOX処理  
- F1SPTITL.ASM ... 曲名リスト  

### PARO-MUS.BAS用
- PARO-MUS.ASM ... JUKE-BOX起動  
- PAROPLAY.ASM ... JUKE-BOX処理  
- PAROTITL.ASM ... 曲名リスト  

### GAL-MUS.BAS用
- GAL-MUS.ASM  ... JUKE-BOX起動  
- GAL-PLAY.ASM ... JUKE-BOX処理  
- GAL-PLKD.ASM ... JUKE-BOX表示処理（漢字版）  
- GAL-TL-K.ASM ... 曲名リスト（漢字版）  

### TFROM.BAS用
- TFROM.ASM  ... ロムの検索とコピー
- KONASRCH.ASM ... 汎用対応向け処理  
- KONALIST.ASM ... コナミゲームID、タイトル名リスト  

