;***************************
; KONAMI 8K MEGAROM UTIL
;***************************

;BIOS LABELS for GAME UTILS
;	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; KONAMI MEGA-ROM BANK
;--------------------------------------
W_BANK:	EQU	0F0F1H	;(4)
BANK0:	EQU	5000H	;4000H-5FFFH
BANK1:	EQU	7000H	;6000H-7FFFH
BANK2:	EQU	9000H	;8000H-9FFFH
BANK3:	EQU	0B000H	;A000H-BFFFH

;KONAMI GAME ID ADDRESS
GAME_ID_ADR:	EQU	4002H
;4095H	GALIOUS
;4099H	PARODIUS
;40E4H	F1-SPIRIT

;--------------------------------------
; KONAMI SCC
;--------------------------------------
;KONAMI SCC COMPATIBLE MODE
SCCR_WAVE1:	equ 9800H	;ch1   波形テーブル 符号付8ビット値 32バイト 9800H-981FH
SCCR_WAVE2:	equ 9820H	;ch2   波形テーブル 符号付8ビット値 32バイト 9820H-983FH
SCCR_WAVE3:	equ 9840H	;ch3   波形テーブル 符号付8ビット値 32バイト 9840H-985FH
SCCR_WAVE4:	equ 9860H	;ch4&5 波形テーブル 符号付8ビット値 32バイト 9860H-987FH
SCCR_TONE1:	equ 9880H	;ch1 周波数分周比 12bit (2 bytes)
SCCR_TONE2:	equ 9882H	;ch2 周波数分周比 12bit (2 bytes)
SCCR_TONE3:	equ 9884H	;ch3 周波数分周比 12bit (2 bytes)
SCCR_TONE4:	equ 9886H	;ch4 周波数分周比 12bit (2 bytes)
SCCR_TONE5:	equ 9888H	;ch5 周波数分周比 12bit (2 bytes)
SCCR_VOL1:	equ 988AH	;ch1 音量 (1 byte)
SCCR_VOL2:	equ 988AH	;ch2 音量 (1 byte)
SCCR_VOL3:	equ 988AH	;ch3 音量 (1 byte)
SCCR_VOL4:	equ 988AH	;ch4 音量 (1 byte)
SCCR_VOL5:	equ 988AH	;ch5 音量 (1 byte)
SCCR_CHENA:	equ 988FH	;channel enable (bit0=ch1 ... bit4 = ch5)
SCCR_MIRROR:	equ 98A0H	;(mirrror of 9889-988FH)
SCCR_MODE:	equ 98E0H	;初期値は0 (98E1-98FF is mirror)
				;bit0: 分周比を4ビットにします。実際の分周比は、分周比レジスタの1／256になります。
				;bit1: 分周比を8ビットにします。ビット8～11は0になります。
				;bit5: 分周比レジスタに値を書き込むと、対応する波形データを先頭から再生しなおします。
				;bit6: 全チャンネルの波形データがローテートします。
				;      方向は、＋0にあったデータが＋1に移動します。
				;      ローテートする時間は、3．58MHz÷（分周比レジスタの値＋1）です。
				;      波形データメモリは全チャンネル書き込み禁止になります。
				;bit7: チャンネルDの波形データのみがローテートします。
				;      波形データメモリはチャンネルD，Eだけが書き込み禁止になります。
				;      このビットは、メガロムでのみ有効です。

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
ROMSLT:	DB	1

;--------------------------------------
; ROM CHECK (FOR BASIC)
; (BASIC) A%=USR(GAME ROM ID)
;	OK:	A%=SLOT
;	NG:	A%=0
;--------------------------------------
ROM_CHK:
	INC	HL	; 
	INC	HL	; (DACINT+2) INT ARGUMENT
	PUSH	HL
	LD	C,1
	CALL	SLTCHK
	JR	Z,ROM_CHKE
	LD	C,2
	CALL	SLTCHK
	JR	Z,ROM_CHKE

;	LD	BC,0FFFFH	;-1
	LD	BC,0
ROM_CHKE:
	; (DACINT+2) = SLOT
	POP	HL
	LD	(HL),C
	INC	HL
	LD	(HL),B	;RET VAL

	;RESTORE SLOT
	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT
	EI
	RET

;--------------------------------------
; CHECK SLOT/EXP SLOT
; IN:	C=SLOT
;	(HL)=ROM ID
; OUT:	NZ:Z
;	OK:NZ, C = SLOT
; USE: ALL
SLTCHK:
	PUSH	HL
	LD	HL,EXPTBL
	LD	A,C
	CALL	ADDHLA
	LD	A,(HL)	;EXPSLT CHECK
	POP	HL
	AND	80H
	LD	A,C
	JR	NZ,EXPSLTC	;EXPANDED
	LD	(ROMSLT),A
	JR	ROMCHK_S
; (CHECK EXP SLOT)
EXPSLTC:
	LD	B,04H
	OR	80H
	LD	C,A
EXPSLTL:
	LD	(ROMSLT),A
	CALL	ROMCHK_S
	RET	Z

	LD	A,C
	ADD	A,04H	;EXPSLT+1
	LD	C,A
	DJNZ	EXPSLTL
	OR	1
	RET

;--------------------------------------
;COMPARE KONAMI ROM ID (4002H)
; IN:	A=SLOT
;	(HL)=ROM ID
; OUT:	Z=NG
;	NZ=OK , C = SLOT
; USE: ALL
ROMCHK_S:
	PUSH	HL
	LD	H,40H
	CALL	ENASLT
	POP	HL

	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	DEC	HL

	EX	DE,HL
	LD	BC,(GAME_ID_ADR)
	OR	A
	SBC	HL,BC
	EX	DE,HL

	LD	BC,(ROMSLT)
	LD	B,0
	RET

