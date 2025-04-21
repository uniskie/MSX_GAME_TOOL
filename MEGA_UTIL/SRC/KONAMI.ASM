;***************************
;   SET TRAP for KONAMI 
;***************************
; for tniasm v0.45
; http://www.tni.nl/products/tniasm.html

; A=USR( TIME-TRAP ﾉ ｱﾄﾞﾚｽ )

SIN10BAI_SEARCH:	EQU	1	;新10倍タイプの検索を使う

;--------------------------------------
	FNAME	"KONAMI.BIN"	;*BINHEAD*
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
;W_BANK:	EQU	0F0F1H
;BANK1:	EQU	7000H
;BANK2:	EQU	9000H
;BANK3:	EQU	0B000H

;--------------------------------------
; ENTRY (EXPORT)
;--------------------------------------
ORGADR:	EQU	0C000H
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
;--------------------------------------
; JUMP TO GAME HKEYI TRAP
TRAP_MS:
	DB	0C3H	;JP
GAME_TRAP_ADR:
	DW	RET_BAS	;RE-WRITE -> GAME_TRAP_ADR

;PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
;	DB	33H,01H,0
;ROMSLT:	DB	1
;CPUSAV:	DB	0

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
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

	EI
	LD	HL,(GAME_MAIN_ADR)
	JP	(HL)
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
