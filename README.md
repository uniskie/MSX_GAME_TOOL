# MSX_GAME_TOOL  
 ハイドライド３、ガリウスの迷宮、パロディウスなどに使うツール  
  
## 変更履歴  
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
  
- GARIOUS.BAS  
...「ガリウスの迷宮」補助ツール  
  
  
処理乗っ取り系のツールなので、  
ROMカートリッジを挿さずに電源にBASICを起動し、  
各種BASICプログラムを実行後、  
該当ROMカートリッジを《後挿し》して使用します。  
  
（スロットは1か2で、拡張スロットも対応しています。）  
  
## その他ツール  
  
- HYD3CHAR.BAS  
...「ハイドライドⅢ」セーブデータ改造ツール  
  
- GAR-MUS.BAS  
...「ガリウスの迷宮」ミュージックボックス  
... ※SAVE-MUS.BASでROMイメージからの吸出しファイルを作成する必要がある  
  
- PARO-MUS.BAS  
...「パロディウス」ミュージックボックス  
...※SAVE-MUS.BASでROMイメージからの吸出しファイルを作成する必要がある  
  
- SAVE-MUS.BAS  
...GAR-MUS.BAS / PARO-MUS.BAS用イメージファイル作成ツール  
  
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
    一時的にスロットを無効化することが可能  
  
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
詳細は [README_HYDLIDE3.TXT](./README_HYDLIDE3.TXT) 参照。  
  
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
  
### PARODIUS.BAS & GARIOUS.BAS  
  
ここでは概要のみ。  
詳細は [README_PARODIUS_GARIOUS.TXT](./README_PARODIUS_GARIOUS.TXT) 参照。  
  
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
  
心配な場合は、新10倍ではなこちらのPARODIUS.BASやGARIUS.BASを使っていただければ、  
ディスク破壊の危険性が少なくなるかと思います。  
  
---  
## ソースファイルについて  
  
srcフォルダにマシン後プログラムのソースが入っています。  
tnimsxを使用してpc上でクロスアセンブルしています。  
makeall.batで一括ビルド可能です。  
  
#### HYDLIDE3.BAS用  
        HYD3-EXP.ASM  
        HYD3STRT.ASM  
  
#### 共用  
        EX-BIOS.ASM  
  
#### GARIOUS.BAS用  
        GAR-EXPS.ASM  
        GAR-TITL.ASM  
        GARSTART.ASM  
  
#### PARODIUS.BAS用  
        PARO-EXP.ASM  
        PARODIUS.ASM  
        PAROPLAY.ASM  
        PAROTITL.ASM  
  
## おまけ  
  
#### 共用  
        KJ-VDP.ASM  ... screen5/7へ漢字表示  
        MOJI-24.ASM ... screen2/4へ文字表示  
  
#### ガリウスの迷宮ミュージックボックス  
        GAR-MUS.BAS  
        GAR-MUS.BOF  
        GAR-MUS.OBJ (同梱無し)  
                    ROMバンク$00,$0d,$0eをつなげたファイル  
        GAR-MUS.ASM  
        GMUS-SUB.ASM  
        GAR-TL-K.ASM  
  
#### パロディウスミュージックボックス  
        PARO-MUS.BAS  
        PARO-MUS.BOF  
        PARO-MUS.OBJ (同梱無し)  
            ROMバンク$00,$04,$05,$06,$0aをつなげたファイル  
        PARO-MUS.ASM  
  
#### ミュージックボックス用ROMイメージ作成ツール  
    （PARO-MUS.OBJ/GAR-MUS.OBJの作成）  
        SAVE-MUS.BAS  
        TFROM.BOF  
        TFROM.ASM  
  
  