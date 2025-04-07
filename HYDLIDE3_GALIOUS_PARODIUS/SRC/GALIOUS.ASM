;**********************************
;   SET TRAP for Maze of GALIOUS
;**********************************
; for tniasm v0.45
; http://www.tni.nl/products/tniasm.html

; A=USR( TIME-TRAP É ±ÄÞÚ½ )

;--------------------------------------
	FNAME	"GALIOUS.BIN"	;*BINHEAD*
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;--------------------------------------

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; GALIOUS ROM ENTRY
;--------------------------------------
GAL_ADR:	EQU	40AEH
MAGICN:	EQU	04095H	;GAME ID

; KONAMI MEGA-ROM BANK
;W_BANK:	EQU	0F0F1H
;BANK1:	EQU	06000H
;BANK2:	EQU	08000H
;BANK3:	EQU	0A000H

;--------------------------------------
; ENTRY (EXPORT)
;--------------------------------------
ORGADR:	EQU	0C000H
	ORG	ORGADR

	JP	GALIOUS_
	JP	ROM_CHK	;KONAMI8K.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
GAL_REF:
	DB	0
GAL_MUS:
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
; ROUTINES
;--------------------------------------
GALIOUS_:
	CALL CPUZ80
	DI			;F3
	LD	(SVW_SP),SP
	CALL	RSLREG
	LD	(W_SLREG),A
	LD	A,V_PG3	;COMMON
	CALL	SAVE_	;COMMON

	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR

	IM	1		;ED 56
	LD	SP,0F0F0H	;31 F0 F0

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT

	LD	A,1
	CALL	CHGCAP	;COMMON

	LD	A,0C3H		;3E C3
	LD	(H_KEYI),A	;32 9A FD
	LD	HL,EX_TRAP	;21 XX XX COMMON
	LD	(H_KEYI+1),HL	;22 9B FD

	LD	A,(GAL_REF)
	DEC	A
	JP	Z,LOAD	;COMMON
	INC	A
	JP	NZ,LOAD_AT	;COMMON
	JP	GAL_ADR

;4002	95 40		DW	4095H

;4095	F3		DI
;4096	ED 56		IM	1
;4098	CD D3 40	CALL	40D3H	;GET PAGE1 SLOT No.
;409B	26 80		LD	H,80H
;409D	CD 24 00	CALL	0024H
;40A0	3E C3		LD	A,0C3H
;40A2	32 9A FD	LD	(H_KEYI),A
;40A5	21 EF 40	LD	HL,40EFH
;40A8	22 9B FD	LD	(H_KEYI+1),HL
;40AB	31 F0 F0	LD	SP,0F0F0H
;40AE

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
;	DI
	LD	A,0DH
	LD	(BANK1),A
	INC	A
	LD	(BANK2),A
	JP	PLAY_TR

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"GAL-PLAY.ASM"	;*FILE*
	INCLUDE	"GAL-EXPS.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*

ENDFL:
