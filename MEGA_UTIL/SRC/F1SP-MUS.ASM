;***************************
;    F1SPIRIT  SOUND-BOX
;***************************
; A=USR( TIME-TRAP ? Å}???? )
	FNAME	"F1SP-MUS.BIN"	;*BINHEAD*
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------

ORGADR:	EQU	0C000H
	ORG	ORGADR

	JP	F1SPIRIT_

;--------------------------------------
; WORK AREA
;--------------------------------------
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	33H,02H,1
;ROMSLT:	DB	1

SVW_SP:	DW	0
SV_HOOK:
	DS	5	;MAIN HOOK BACKUP

;W_SBANK:
;	DB	0

TRAP_READY:
	DB	0

;--------------------------------------
F1SPIRIT_:
	DI
	LD	(SVW_SP),SP

	XOR	A
	LD	(TRAP_READY),A

	LD	HL,8000H
	LD	B,40H
	LD	A,4
	LD	C,0+40H
	CALL	TF_VRM

	LD	HL,0E000H
	LD	B,1FH
	LD	A,7
	LD	C,20H+40H
	CALL	TF_VRM

	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR

;	IM	1
;	LD	SP,0F0F0H	;(0F378H)
	LD	SP,0D300H	;(0F378H)

	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT
	LD	A,(RAMAD0+1)
	LD	H,40H
	CALL	ENASLT

	CALL	RSLREG
	LD	(SEL_SCC+1),A
	LD	A,3FH
	LD	(9000H),A

	LD	A,(RAMAD0+2)
	LD	H,80H
	CALL	ENASLT
	CALL	RSLREG
	LD	(RET_SCC+1),A
	CALL	SETRAM

	LD	HL,PLAY_TRAP
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A

	JP	PLAY

;--------------------------------------
RET_BAS:
	DI

	LD	HL,SV_HOOK
	LD	DE,H_KEYI
	LD	BC,5
	LDIR

	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT
	LD	A,(RAMAD0+2)
	LD	H,80H
	CALL	ENASLT

	LD	HL,8000H
	LD	B,40H
	LD	A,4
	LD	C,0
	CALL	TF_RAM
	LD	HL,0E000H
	LD	B,1FH
	LD	A,7
	LD	C,20H
	CALL	TF_RAM

	LD	SP,(SVW_SP)	;COMMON
;	IM	0
	EI

	RET

;--------------------------------------
;;WRITE SCC REGISTER 
;; (SCC_BANK:DE)=(SRC_BANK:HL)
;; BANK2=2 *** CAUTION ***
;.WRITE_SCC: 
; LD	A,(HL)		;6DA1: 7E
; LD	C,A		;6DA2: 4F
; LD	A,#3F		;6DA3: 3E 3F
; LD	(BANK2),A	;6DA5: 32 00 90
; LD	A,C		;6DA8: 79
; LD	(DE),A		;6DA9: 12
; LD	A,#02		;6DAA: 3E 02
; LD	(BANK2),A	;6DAC: 32 00 90
; RET			;6DAF: C9

;--------------------------------------
;WRITE_SCC_WAVE: 
; LD	A,#3F		;6E04: 3E 3F
; LD	(BANK2),A	;6E06: 32 00 90
; XOR	A		;6E09: AF
; LD	(SCCR_CHENA),A	;6E0A: 32 8F 98
; LD	B,#20		;6E0D: 06 20
;.X6E0F: 
; LD	A,(HL)		;6E0F: 7E
; LD	(DE),A		;6E10: 12
; INC	HL		;6E11: 23
; INC	DE		;6E12: 13
; DJNZ	.X6E0F		;6E13: 10 FA
; LD	HL,SCCR_CHENA	;6E15: 21 8F 98
; LD	DE,SCCWCHEN	;6E18: 11 8F E1
; LD	A,(DE)		;6E1B: 1A
; LD	(HL),A		;6E1C: 77
; LD	A,#02		;6E1D: 3E 02
; LD	(BANK2),A	;6E1F: 32 00 90
; RET			;6E22: C9

;--------------------------------------
SETRAM:	LD	A,5
	LD	C,0
	LD	HL,6000H
	LD	B,60H
	CALL	TF_RAM

;	LD	HL,MSET_R0
;	LD	DE,661DH
;	LD	BC,8
;	LDIR

	;PATCH
	LD	DE,6DA3H
	CALL	LD_SELSCC
	LD	DE,6E04H
	CALL	LD_SELSCC

	LD	DE,6DAAH
	CALL	LD_RETSCC
	LD	DE,6E1DH
	CALL	LD_RETSCC

	RET
;--------------------------------------
LD_SELSCC:
	LD	HL,SEL_SCC
	LD	BC,5
	LDIR
	RET
LD_RETSCC:
	LD	HL,RET_SCC
	LD	BC,5
	LDIR
	RET

;MSET_R0:
;	LD	L,A
;	LD	A,(W_SBANK)
;	CP	L
;	CALL	NZ,SL_BANK
;
;SL_BANK:
;	LD	DE,0620H
;	LD	A,L
;	LD	(W_SBANK),A
;	OR	A
;	JP	Z,SB_NO6
;	LD	DE,0700H
;SB_NO6:	LD	A,D
;	LD	C,E
;	LD	HL,0A000H
;	LD	B,20H
;	CALL	TF_RAM
;	RET

SEL_SCC:
	LD	A,0F1H	;?(rewrite)SCC SLOT
	CALL	WSLREG
	RET
RET_SCC:
	LD	A,0F3H	;?(rewrite)NOT SCC SLOT
	CALL	WSLREG
	RET

;--------------------------------------
PLAY:	LD	HL,0E000H
	LD	DE,0E001H
	LD	BC,0FFFH
	LD	(HL),0
	LDIR

	LD	A,1
	LD	(TRAP_READY),A

	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	XOR	A
	LD	(TRAP_READY),A

	JP	RET_BAS

;--------------------------------------
PLAY_TRAP:
	LD	A,(TRAP_READY)
	OR	A
	JP	NZ,PLAY_TR

	; NOT READY
	CALL	RDVDP
	EI
	RET

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"F1SPPLAY.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
ENDFL:
