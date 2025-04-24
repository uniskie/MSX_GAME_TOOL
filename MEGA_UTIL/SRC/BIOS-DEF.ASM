; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

#pragma once

;BIOS LABELS for GAME UTILS

;******************************
; I/O port
;******************************
VDP:	EQU	98H

KEYIO:	EQU	0A9H
KEYIO0:	EQU	KEYIO+0
KEYIO1:	EQU	KEYIO+1

PSGIO:	EQU	0A0H
PSGIOA:	EQU	PSGIO+0
PSGIOW:	EQU	PSGIO+1
PSGIOR:	EQU	PSGIO+2

RAMSG0:	EQU	0FCH	;default=3
RAMSG1:	EQU	0FDH	;default=2
RAMSG2:	EQU	0FEH	;default=1
RAMSG3:	EQU	0FFH	;default=0

;******************************
; BDOS
;******************************
SYSCAL:	EQU	0F37DH

;******************************
; BIOS CONSTANTS
;******************************
MSXSIG:	EQU	002DH	;MSX ROM VERSION (MSX1=0,MSX2=1,...)

;******************************
;CPU
;******************************
CHGCPU:	EQU	0180H
GETCPU:	EQU	0183H

;******************************
;GENERAL PORT
;******************************
CHGCAP:	EQU	0132H	;CAP ランプの状態を変える A=0:点灯/O以外:消灯
CHGSND:	EQU	0135H	;1ビットサウンドポート

;CAPS
CAPST:	EQU	0FCABH	;[CAPS]キーの状態

;その他スクリーン設定
CLIKSW: equ 0F3DBH ;(1)   (初期値 1) キークリックスイッチ(0=OFF、0以外=ON)。SCREEN文の<キークリックスイッチ>により設定される

;******************************
;PSG
;******************************
WRTPSG:	EQU	0093H ;PSG のレジスタにデータを書き込む A にPSG のレジスタ番号、E にデータ
RDPSG:	EQU	0096H ;PSG のレジスタの値を読む A に PSG のレジスタ番号

;******************************
; SLOT
;******************************
RDSLT:	EQU	000CH	;指定スロットの指定アドレスから値を読む
WRLST:	EQU	0014H	;指定スロットの指定アドレスに値を書き込む
CALSLT:	EQU	001CH	;指定したスロットの指定アドレスをコールする
ENASLT:	EQU	0024H	;スロットを切り換える 
RSLREG:	EQU	0138H	;基本スロット選択レジスタの読み出し
WSLREG:	EQU	013BH	;基本スロット選択レジスタへの書き込み
CALLF:	EQU	0030H	;指定スロットの指定アドレスをコールする RST 30H

;SLOT INFO
EXPTBL:	EQU	0FCC1H	;(4)   拡張スロット用のフラグテーブル。各スロットの拡張の有無
;EXPTB0:	EQU	EXPTBL+0
EXPTB1:	EQU	EXPTBL+1
EXPTB2:	EQU	EXPTBL+2
EXPTB3:	EQU	EXPTBL+3
SLTTBL:	EQU	0FCC5H ;(4)   各拡張スロットレジスタ用の、現在のスロット選択状況
;SLTTBL0:EQU	SLTTBL+0
SLTTBL1:EQU	SLTTBL+1
SLTTBL2:EQU	SLTTBL+2
SLTTBL3:EQU	SLTTBL+3
RAMAD0:	equ	0F341h ;(2)  PAGE0のRAMスロット番号
RAMAD1:	equ	0F342h ;(2)  PAGE1のRAMスロット番号
RAMAD2:	equ	0F343h ;(2)  PAGE2のRAMスロット番号
RAMAD3:	equ	0F344h ;(2)  PAGE3のRAMスロット番号
DSKSYS:	equ	0F436h ;(1)   0以外の値を書き込むとBASICからDOSへ行ける

;******************************
; TIMER INTERRUPT VECTOR
;******************************
KEYINT:	EQU	0038H	;TIMER

;******************************
; VDP / VRAM ACCESS
;******************************

WRTVRM:	EQU	004DH	;HL=VRAM ADDRESS(14bit),
SETWRT:	EQU	0053H	;HL=VRAM ADDRESS(14bit), A=DATA
FILVRM:	EQU	0056H	;HL=VRAM ADDRESS(14bit), BC=SIZE, A=DATA

CHGMOD:	EQU	005FH	;スクリーン・モードを変える。パレットは初期化しない。A にスクリーンモード (0～8)

RDVDP:	EQU	013EH	;VDP のステータス・レジスタを読む

NSTWRT:	EQU	0171H	;HL=VRAM ADDRESS(16bit),
NWRVRM:	EQU	0177H	;HL=VRAM ADDRESS(16bit), A=DATA
BIGFIL:	EQU	016BH	;HL=VRAM ADDRESS(16bit), BC=SIZE, A=DATA

DCOMPR:	EQU	0020H	;HL と DE の内容を比較 (USE:AF)

REG0SV:		EQU	0F3DFH	;VDP REG#0-#7
RG8SAV:		EQU	0FFE7H	;VDP REG#8-#23
RG18SAV:	EQU	RG8SAV+18-8 ;SET ADJUST
RG19SAV:	EQU	RG8SAV+19-8
RG23SAV:	EQU	RG8SAV+23-8
RG25SAV:	EQU	0FFF8H	;VDP REG#25-#27

;******************************
; BASIC INTERNAL
;******************************
KBUF:   equ 0F41FH ;(318) クランチバッファ。BUF(0F55EH)から中間言語に直されて入る

MEMSIZ: equ 0F672H ;(2)   BASICが使用するメモリの最上位番地
STKTOP: equ 0F674H ;(2)   BASICがスタックとして使用する番地。CLEAR文により変化する
TXTTAB: equ 0F676H ;(2)   BASICテキストエリアの先頭番地
TEMPPT: equ 0F678H ;(2)   (初期値 TEMPST(0F67AH)) テンポラリディスクリプタの空きエリアの先頭番地
TEMPST: equ 0F67AH ;(3 * NUMTMP) NUMTEMP用の領域
DSCTMP: equ 0F698H ;(3)   ストリング関数の答えのストリングディスクリプタが入る
FRETOP: equ 0F69BH ;(2)   文字列領域の空きエリアの先頭番地
TEMP3:  equ 0F69DH ;(2)   ガベージコレクションやUSR関数などに使われる
TEMP8:  equ 0F69FH ;(2)   ガベージコレクション用

;******************************
; BIOS WORK AREA
;******************************
;MEMORY BLOCK
HIMEM:	EQU	0FC4AH	;BASIC FREE AREA
BLDCHK:	EQU	0F377H	;DISK WORK AREA HEAD

;MATH-PACK/USER関数
VALTYP:	EQU	0FF63H	;(1)
DAC:	EQU	0F7F6H	;(16)
DACINT:	EQU	0F7F8H	;(2)

;FONT
CGPNT:	EQU	0F91FH	;(1) ROM FONT SLOT
BASFNT:	EQU	CGPNT+1	;(2) ROM FONT ADDRESS

;TIMER HOOK
H_KEYI:	EQU	0FD9AH
H_TIMI:	EQU	0FD9FH

;******************************
; BIOS WORK AREA
; for Temporary use
;******************************
; BASIC TOKEN
BUF:	EQU	0F55EH+1	;0F55EH,258

;PLAY/DRAW(BASIC)
;	NG:MCLTAB:	EQU	0F956H	;2  
;	NG:MCLFLG:	EQU	0F958H	;1  
;	NG:QUETAB:	EQU	0F959H	;24 	安全ではない
;	NG:QUEBAK:	EQU	0F971H	;4  

VOICAQ:	EQU	0F975H	;128	PLAY/DRAWを使わなければ安全
VOICBQ:	EQU	0F9F5H	;128
VOICCQ:	EQU	0FA75H	;128
VOICQM:	EQU	VOICCQ+128	;0FAF5H ... LIMIT
VOICQS:	EQU	128+128+128	;VOICAQ-VOICCQ SIZE

;PLAY(BASIC)
SAVSP:	EQU	0FB36H	;2	PLAY文実行中にスタックポインタを保存
VCBA:	EQU	0FB41H	;37
VCBB:	EQU	0FB66H	;37
VCBC:	EQU	0FB8BH	;37
VCBSZ:	EQU	37+37+37	;VCBA-VCBC SIZE(DAT+STACK)
