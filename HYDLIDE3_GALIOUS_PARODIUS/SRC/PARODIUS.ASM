;***************************
;   SET TRAP for  PARODIUS
;***************************
; for tniasm v0.45
; http://www.tni.nl/products/tniasm.html

; A=USR( TIME-TRAP É ±ÄÞÚ½ )

;--------------------------------------
	FNAME	"PARODIUS.BIN"	;*BINHEAD*
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;--------------------------------------

;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; PARODIUS ROM ENTRY
;--------------------------------------
PAR_ADR:	EQU	40A7H
MAGICN:	EQU	04099H	;GAME ROM CHEK ID

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

	JP	PARODIUS_
	JP	ROM_CHK	;KONAMI8K.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
PAR_REF:
	DB	0
PAR_MUS:
	DB	88H,01H,0
;ROMSLT:	DB	1
;CPUSAV:	DB	0

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
W_SLREG:
	DB	0
SV_HOOK:
	DS	5
SVPHOOK:
	DS	5

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
PARODIUS_:
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


;	IM	1
	LD	SP,0F0F0H

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT

	LD	A,1
	CALL	CHGCAP	;COMMON

	LD	HL,EX_TRAP	;COMMON
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A

	LD	A,(PAR_REF)
	DEC	A
	JP	Z,LOAD	;COMMON
	INC	A
	JP	NZ,LOAD_AT	;COMMON
	JP	PAR_ADR

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

	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	LD	A,7
	OUT	(PSGIOA),A	;COMMON
	LD	A,0BFH
	OUT	(PSGIOW),A	;COMMON

	LD	A,3FH
	LD	(BANK2),A
	XOR	A
	LD	(SCCMIX),A

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

PLAY_TRAP:
	LD	A,4
	LD	(BANK1),A
	INC	A
	LD	(BANK2),A
	INC	A
	LD	(BANK3),A
	JP	PLAY_TR

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"PAROPLAY.ASM"	;*FILE*
	INCLUDE	"PARO-EXP.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
;--------------------------------------
; ENASLT CLONE (FOR PAGE 0 SLOT CHANGE)
	INCLUDE "CHGSLT.ASM"	;*FILE*
;--------------------------------------
ENDFL:
