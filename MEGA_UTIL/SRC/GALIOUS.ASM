;**********************************
;   SET TRAP for Maze of GALIOUS
;**********************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
;GAME:
;	VRAM: 16KByte
;	RAM : 8KByte ($e000-$fc00)
;--------------------------------------
;VRAM SAVE Version:(Current Version)
; * MSX1: not work
; * RAM: 8KB
; * VRAM SAVE: easy in BASIC
; * Save Slot: 2
;
;$0000	(GAME)                    4KBytes
;$4000	(EMPTY)                   4KBytes
;$8000	AUTO SAVE  RAM  E000-FFFF 8KBytes
;	AUTO SAVE  VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;$10000	STATE SAVE RAM  E000-FFFF 8KBytes
;	STATE SAVE VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;$18000	BASIC      RAM  E000-FFFF 8KBytes
;	BASIC      VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;--------------------------------------


ORGADR:	EQU	0C000H

;--------------------------------------
;	FNAME	"GALIOUS.BIN"	;*BINHEAD*
	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;--------------------------------------

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

; GALIOUS ROM ENTRY
GAL_ADR:	EQU	40AEH
TRAP_MS:	EQU	40EFH	;M-GALIOUS
ROMINIT:	EQU	04095H	;GAME ID
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

	JP	GALIOUS_
	JP	ROM_CHK	;KONAMI8K.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
SAV_REF:
	DB	0
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	87H,01H,2
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

;	IM	1
	LD	SP,GAMESPA

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT

	LD	A,1
	CALL	CHGCAP	;COMMON

	LD	A,0C3H
	LD	(H_KEYI),A
	LD	HL,EX_TRAP	;GAL-EXP.ASM
	LD	(H_KEYI+1),HL

	LD	A,(SAV_REF)
	DEC	A
	JP	Z,LOAD	;GAL-EXP.ASM
	INC	A
	JP	NZ,LOAD_AT	;GAL-EXP.ASM
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

	CALL	SET_PLAYBANK
	JP	PLAY_SUB

;--------------------------------------
PLAY_R:
	DI
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
	CALL	RESTORE_BANK

PLAY_TRAP_E:
	CALL	RDVDP
	EI
	RET

SET_PLAYBANK:
	LD	A,0DH
	LD	(BANK1),A
	INC	A
	LD	(BANK2),A
	RET

RESTORE_BANK:
;	LD	A,(WBANK0)
;	LD	(BANK0),A
	LD	A,(WBANK1)
	LD	(BANK1),A
	LD	A,(WBANK2)
	LD	(BANK2),A
	RET

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"
	INCLUDE	"GAL-PL-D.ASM"
	INCLUDE	"GAL-PLAY.ASM"
	INCLUDE	"GAL-EXPS.ASM"
	INCLUDE	"EX-BIOS.ASM"
	INCLUDE	"GAL-TITL.ASM"

ENDFL:
