;*************************************
; SET EX-TRAP : RC-751 GRADIUS2
;*************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

ORGADR:	EQU	0C000H

;--------------------------------------
;	FNAME	"GRADIUS2.BIN"	;*BINHEAD*

	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

; GRADIUS2 ROM ENTRY
RUN_ADR:	EQU	409EH
TRAP_MS:	EQU	4023H	;GRADIUS2
ROMINIT:	EQU	4090H	;GAME ROM CHEK ID
MUSBANK:	EQU	04H
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

	JP	GAMEBOOT_
	JP	ROM_CHK	;KONAMI8K.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
SAV_REF:
	DB	0
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	3FH,01H,2
;ROMSLT:	DB	1
;CPUSAV:	DB	0

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
W_SLREG:
	DB	0
SV_HOOK:
	DBFIL	5
SVPHOOK:
	DBFIL	5

;--------------------------------------
; ROUTINES
;--------------------------------------

; FROM BASIC
GAMEBOOT_:
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
;	IM	1
	LD	SP,GAMESPA

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

	LD	A,(SAV_REF)
	DEC	A
	JP	Z,LOAD	;COMMON
	INC	A
	JP	NZ,LOAD_AT	;COMMON

	JP	RUN_ADR

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
PLAY:	LD	HL,H_KEYI
	LD	DE,SVPHOOK
	LD	BC,5
	LDIR

	DI
	LD	A,0C3H
	LD	HL,PLAY_TRAP
	LD	(H_KEYI),A
	LD	(H_KEYI+1),HL

	LD	A,V_PG1	;COMMON
	CALL	SAVE_	;COMMON

	LD	A,(RG8SAV)
	OR	2
	OUT	(VDP+1),A	;SPRITE OFF
	LD	A,8+80H
	OUT	(VDP+1),A
	XOR	A
	OUT	(VDP+1),A	;BACK COLOR=0
	LD	A,7+80H
	OUT	(VDP+1),A

	CALL	SET_PLAYBANK
	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	LD	DE,H_KEYI
	LD	HL,SVPHOOK
	LD	BC,5
	LDIR

	LD	A,V_PG1	;COMMON
	CALL	LOAD_	;COMMON

	LD	A,(RG8SAV)
	AND	253
	OUT	(VDP+1),A	;SPRITE ON
	LD	A,8+80H
	OUT	(VDP+1),A

	LD	DE,0801H	;'SPC'
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,$-6
	JP	RETURN

;--------------------------------------
PLAY_TRAP:
	CALL	SET_PLAYBANK
	CALL	PLAY_TR
	RET

;--------------------------------------
SET_PLAYBANK:
	LD	A,MUSBANK
	LD	(BANK1),A
	INC	A
	LD	(BANK2),A
	INC	A
	LD	(BANK3),A
	RET

;--------------------------------------
SEL_SCC:
	LD	A,3FH
	LD	(BANK2),A
	RET

RET_SCC:
	RET

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"
	INCLUDE	"GRA2PLAY.ASM"
	INCLUDE	"GRA2-EXP.ASM"
	INCLUDE	"EX-BIOS.ASM"
;--------------------------------------
; ENASLT CLONE (FOR PAGE 0 SLOT CHANGE)
;	INCLUDE "CHGSLT.ASM"
;--------------------------------------
ENDFL:
