# DISC STATIONからゲームを取り出すツール

ディスクステーションのディスクイメージを元に
収録されているゲームのROMファイルを作成するバッチファイルです。

WINDOWS用です。

動作保証やサポートはありません。

| 収録 | バッチファイル         | ゲーム名                | 出力ファイル | 元イメージ  |
|------|------------------------|-------------------------|--------------|-------------|
| 00号 | HustleChumy_DS.bat     | ハッスルチューミー      | HUSTLEDS.ROM | DS#0.DSK    |
| 01号 | MEGALOPOLIS_SOS_DS.bat | メガロポリスSOS         | MEGARODS.ROM | DS#1-1.DSK  |
| 02号 | SWING_DS.bat           | 窓ふき会社のスイング君  | SWING_DS.ROM | DS#2-2.DSK  |
| 03号 | GODZILLA_DS.bat        | ゴジラくん              | GODZILDS.ROM | DS#3-2.DSK  |
| 04号 | EGGY_DS.bat            | EGGY                    | EGGY_DS.ROM  | DS#4-2.DSK  |
| 05号 | MACCROSS_DS.bat        | マクロス カウントダウン | MACROSDS.ROM | DS#5-2.DSK  |
| 06号 | XYXOLOC_DS.bat         | XYXOLOC                 | XYXOLODS.ROM | DS#6-1.DSK  |
| 07号 | CSO_DS.bat             | C-SO!                   | CSO_DS.ROM   | DS#7-2.DSK  |
| 08号 | FINALJUSTICE_DS.bat    | FINAL JUSTICE           | FINALJDS.ROM | DS#8-1.DSK  |
| 09号 | GULKAVE_DS.bat         | GULKAVE                 | GULKAVDS.ROM | DS#9-2.DSK  |
| 10号 | CRUSADER_DS.bat        | CRUSADER                | CRUSADDS.ROM | DS#10-1.DSK |
| 15号 | EI_DS.bat              | E.I. (EXA INOVA)        | EI_DS.ROM    | DS#15-1.DSK |

## 必要ツール

bincut2.exe     ... バイナリーカッター  
https://nezplug.sourceforge.net/  
https://www.purose.net/befis/download/nezplug/oldsite.shtml  

## 注意：CRUSADDS.ROM

openMSXではCRUSADDS.ROMのROMタイプを正常に判定できないので、
ROM TYPEは手動で`NORMAL4000`または`Plain 32K page1-2`を指定してください。


オリジナル版でもDS版でも、MSX1以外では起動に失敗することがあります。
（リセットすれば動くことがあるそうです）

原因は起動時のFILVRM中に割り込みが発生するとBCレジスタを破壊する事です。
CRUSADER_DS.batではこの問題を修正しています。

> ```
>  POP    IX             	;4815: DD E1
>  POP    IY             	;4817: FD E1
>  POP    AF             	;4819: F1
>  POP    BC             	;481A: C1
>  POP    DE             	;481B: D1
>  POP    HL             	;481C: E1
>  EX     AF,AF'         	;481D: 08
>  EXX                   	;481E: D9
>  POP    AF             	;481F: F1
>  POP    BC             	;4820: C1
>  POP    DE             	;4821: D1
>  POP    HL             	;4822: E1
>  CALL   #433E          	;4823: CD 3E 43	; この先でレジスタ破壊
>  EI                    	;4826: FB
>  RET                   	;4827: C9
> 
> 
> .X4338: 
>  LD     BC,#C201       	;4338: 01 01 C2
> .X433B: 
>  JP     WRTVDP         	;433B: C3 47 00
>  LD     BC,#E201       	;433E: 01 01 E2 ;ここでBC破壊
>  JR     .X433B         	;4341: 18 F8
> ```
> 
> 対処内容：`CALL   #433E`を`POP IX`の前に移動

