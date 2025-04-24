;***************************
; KONAMI8K SAVE to VRAM
;***************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
USE_SIN10BAI_SEARCH:	EQU	1	;新10倍タイプの検索を使う
SEARCH_ID_ONLY:		EQU	1	;ID検索のみ行う（スタックポインタ、フック、EIなどを検査しない）
;--------------------------------------

ORGADR:	EQU	0C000H

;--------------------------------------
;	FNAME	"TFROM.BIN"	;*BINHEAD*
	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;WBANK0:	EQU	0F0F0H
;WBANK1:	EQU	0F0F1H
;WBANK2:	EQU	0F0F2H
;WBANK3:	EQU	0F0F3H
;BANK0:	EQU	5000H
;BANK1:	EQU	7000H
;BANK2:	EQU	9000H
;BANK3:	EQU	0B000H

;--------------------------------------
	ORG	ORGADR

	JP	SEARCH_ROM_BAS	;KONASRCH.ASM
	JP	GET_SLOT_BAS	;KONASRCH.ASM
	JP	GET_GAME_ID_BAS	;KONASRCH.ASM
	JP	GET_TITLE_BAS	;KONASRCH.ASM
	JP	ROM_CPY

;--------------------------------------
	
;ROMSLT:	DB	1
;CPUSAV:	DB	0

;--------------------------------------
;ADDHLA:	ADD	A,L
;	LD	L,A
;	RET	NC
;	INC	H
;	RET

;--------------------------------------
; A=USR(バンク配列文字列)
;	最初の2byte：転送先VRAMアドレス
;	3文字目以降：バンク番号1byte*N個
;	VRAM 10000H-に転送
ROM_CPY:
	CP	3
	RET	NZ	; 文字列以外不可
	EX	DE,HL
	LD	A,(HL)
	INC	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	PUSH	AF
	PUSH	DE
	PUSH	DE
	POP	IX
	LD	B,A	;文字数
	PUSH	BC

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	DI

	LD	E,(IX+0)
	LD	D,(IX+1)	;VRAM 10000H+??
	INC	IX
	INC	IX
TFBANK_L:
	POP	BC
	LD	A,B
	OR	A
	JR	Z,TFBANK_E	;END
	DEC	B
	PUSH	BC

	LD	A,(IX+0)
	INC	IX
	LD	(BANK1),A

	LD	A,D
	AND	3FH
	OR	40H	;WRITE BIT
	LD	C,A	;bit8-13
	LD	A,D
	SCF	;bit16	;SCREEN5 PAGE2/SCREEN7 PAGE1
	RLA
	RLA
	RLA
	AND	7	;bit12-16
	LD	B,20H	;2000H/100H
	LD	HL,6000H	;BANK1
	CALL	TF_VRM

	LD	HL,2000H
	ADD	HL,DE
	EX	DE,HL	;VRAM ADR+2000H
	JR	TFBANK_L

TFBANK_E:
	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT
	EI

	POP	HL
	POP	AF
	CP	1
	RET	C
	LD	A,255
	LD	(HL),A
	RET

;--------------------------------------
	INCLUDE "KONASRCH.ASM"	;*FILE*
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
ENDFL:
