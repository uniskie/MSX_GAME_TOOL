;***************************
;   SET TRAP for KONAMI 
;***************************
ORGADR:	EQU	0C000H
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

; A=USR( TIME-TRAP ﾉ ｱﾄﾞﾚｽ )

SIN10BAI_SEARCH:	EQU	1	;新10倍タイプの検索を使う
KONAMI_MSX1_ONLY:	EQU	1	;KONAMI MSX1 ソフトのみ
KONAMI_MSX1_E000: 	EQU	1	;ワークエリアがE000H以上のソフトのみ

;--------------------------------------
;	FNAME	"KONAMI.BIN"	;*BINHEAD*
	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;--------------------------------------

;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; F1SPIRIT ROM ENTRY
;--------------------------------------

GAMESPA:	EQU	0F0F0H

; KONAMI MEGA-ROM BANK
;WBANK0:	EQU	0F0F0H
;WBANK1:	EQU	0F0F1H
;WBANK2:	EQU	0F0F2H
;WBANK3:	EQU	0F0F3H
;BANK0:	EQU	5000H
;BANK1:	EQU	7000H
;BANK2:	EQU	9000H
;BANK3:	EQU	0B000H

;--------------------------------------
; ENTRY (EXPORT)
;--------------------------------------
	ORG	ORGADR

	JP	BOOTGAME_
	JP	SEARCH_ROM_BAS	;KONASRCH.ASM
	JP	GET_SLOT_BAS	;KONASRCH.ASM
	JP	GET_GAME_ID_BAS	;KONASRCH.ASM
	JP	GET_TITLE_BAS	;KONASRCH.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
;SYSTEM SAVE FLAG
SSAV_REF:
	DB	0
;ROMSLT:	DB	1
;CPUSAV:	DB	0
RESULT:
R_GAME_ID:
	DW	0
R_GAME_TITLE:
	DB	0,"                           "	;文字数,27文字
;--------------------------------------
GAME_SP_ADR:
	DW	0F0F0H
GAME_MAIN_ADR:
	DW	RET_BAS
;GAME_TRAP_ADR:
;	DW	0000H
NEED_EI:
	DB	0
GAMEWORK_INIT_SIZE:
	DW	0	;3FFHとか1FFHとか

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
;--------------------------------------
; JUMP TO GAME HKEYI TRAP
TRAP_MS:
	DB	0C3H	;JP
GAME_TRAP_ADR:
	DW	RET_BAS	;RE-WRITE -> GAME_TRAP_ADR

;PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
;	DB	33H,01H,0
W_SLREG:
	DB	0
SV_HOOK:
	DB	0C9H,0C9H,0C9H,0C9H,0C9H
SVPHOOK:
	DB	0C9H,0C9H,0C9H,0C9H,0C9H

;--------------------------------------
;GAME:
;	VRAM: 16KByte
;	RAM : 8KByte ($e000-$fc00)
;--------------------------------------

;--------------------------------------
;VRAM SAVE Version:(Current Version)
; * MSX1: not work
; * VRAM SAVE: easy in BASIC
; * Save Slot: 2

;$4000	AUTO STATE RAM 8KByte
;	AUTO STATE VRAM 16KByte
;$8000	STATE RAM 8KByte
;	STATE VRAM 16KByte
;$10000	BASIC RAM 8KByte
;	BASIC VRAM 16KByte
;--------------------------------------
;RAM SAVE Version:(Scrapped Plan)
; * MSX1: work
; * VRAM SAVE: Difficult in BASIC.
; * Save Slot: 1

;$0000	BASIC RAM 8KByte
;$2000	STATE RAM 8KByte
;$4000	STATE VRAM 16KByte
;--------------------------------------

;--------------------------------------
; ROUTINES
;--------------------------------------
BOOTGAME_:
	; FROM BASIC
	CALL CPUZ80
	DI
	LD	(SVW_SP),SP
	CALL	RSLREG
	LD	(W_SLREG),A
	LD	A,V_PG3	;COMMON
	CALL	SAVE_	;COMMON

	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR

	; KONAMI MSX1 DEFAULT VDP CONFIG
	; VDPワークエリアを更新しない一部ソフトの対策
	; (わんぱくアスレチックなど)
	LD	HL,KONAMI_VDP_DEF
	LD	DE,REG0SV
	LD	BC,8
	LDIR
	CALL	WR_CRG

	; INIIALIZE GAME
	IM	1
	LD	HL,(GAME_SP_ADR)
	LD	SP,HL

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT

	XOR	A
	LD	(CLIKSW),A

	LD	A,1
	CALL	CHGCAP	;COMMON

	LD	HL,EX_TRAP	;COMMON
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A

	LD	A,(SSAV_REF)
	DEC	A
	JP	Z,LOAD	;COMMON
	INC	A
	JP	NZ,LOAD_AT	;COMMON

NEW_GAME:
	DI

	LD	BC,(GAMEWORK_INIT_SIZE)
	LD	A,B
	OR	C
	JR	Z,NEW_GAME_

	;MEMORY CLEAR
	LD     HL,0E000H	;21 00 E0
	LD     DE,0E001H	;11 01 E0
	LD     (HL),0		;36 00
	LDIR			;ED B0

NEW_GAME_:

	CALL	RDVDP
	LD	A,(NEED_EI)
	OR	A
	JR	Z,NOT_USE_EI

	EI

NOT_USE_EI:
	LD	HL,(GAME_MAIN_ADR)
	JP	(HL)

KONAMI_VDP_DEF:
	;	R#0  R#1  R#2  R#3  R#4  R#5  R#6  R#7
	DB	02H, 62H, 0EH, 7FH, 07H, 76H, 03H,0E1H
	;SCREEN: GRAPHIC2, ENABLE
	;FREQ:NTSC
	;LINES:192
	;INTERLACE:NONE, FLIP:NONE
	;SPRITE: ENABLE, 16X16, x1
	;COLOR0: TRANSPARENT
	;VBLANK-IRQ:ENABLE
	;HBLANK-IRQ:DISABLE
	;PAT GEN:2000H
	;PAT COL:0000H
	;PAT NAM:3800H
	;SPR PAT:1800H
	;SPR ATR:3B00H

;--------------------------------------
RET_BAS:
	LD	A,(W_SLREG)
	CALL	WSLREG

	LD	HL,SV_HOOK
	LD	DE,H_KEYI
	LD	BC,5
	LDIR
	LD	SP,(SVW_SP)	;COMMON
;	IM	0
	EI

	CALL	CPURES
	RET

;--------------------------------------
;PLAY:	LD	HL,H_KEYI
;	LD	DE,SVPHOOK
;	LD	BC,5
;	LDIR
;
;	DI
;	LD	A,0C3H
;	LD	HL,PLAY_TRAP
;	LD	(H_KEYI),A
;	LD	(H_KEYI+1),HL
;
;	LD	A,V_PG1	;COMMON
;	CALL	SAVE_	;COMMON
;
;	LD	A,(RG8SAV)
;	OR	2
;	OUT	(VDP+1),A	;SPRITE OFF
;	LD	A,8+80H
;	OUT	(VDP+1),A
;	XOR	A
;	OUT	(VDP+1),A	;BACK COLOR=0
;	LD	A,7+80H
;	OUT	(VDP+1),A
;
;	JP	PLAY_SUB
;
;;--------------------------------------
;PLAY_R:	DI
;	LD	DE,H_KEYI
;	LD	HL,SVPHOOK
;	LD	BC,5
;	LDIR
;
;	LD	A,V_PG1	;COMMON
;	CALL	LOAD_	;COMMON
;
;
;	LD	A,(RG8SAV)
;	AND	253
;	OUT	(VDP+1),A	;SPRITE ON
;	LD	A,8+80H
;	OUT	(VDP+1),A
;
;	LD	DE,0801H	;'SPC'
;	CALL	KEYIN	;D=KEYMTX NO / E=MASK
;	JP	Z,$-6
;	JP	RETURN
;
;;--------------------------------------
;PLAY_TRAP:
;	LD	A,0DH
;	LD	(BANK1),A
;	INC	A
;	LD	(BANK2),A
;	INC	A
;	LD	(BANK3),A
;	JP	PLAY_TR

;--------------------------------------
SEL_SCC:
	LD	A,3FH
	LD	(BANK2),A
	RET

RET_SCC:
	RET

;--------------------------------------
	INCLUDE "KONASRCH.ASM"	;*FILE*
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"KONA-EXP.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
;--------------------------------------
; ENASLT CLONE (FOR PAGE 0 SLOT CHANGE)
	INCLUDE "CHGSLT.ASM"	;*FILE*
;--------------------------------------
ENDFL:

#IF (RESULT + KONAMI_ID_ISIZE) > GAME_SP_ADR
	#PRRINT "[ERROR] (RESULT + KONAMI_ID_ISIZE) > GAME_SP_ADR"
#ENDIF
