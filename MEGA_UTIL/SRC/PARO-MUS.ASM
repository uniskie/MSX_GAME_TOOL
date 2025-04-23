;***************************
;    PARODIUS  SOUND-BOX
;***************************
ORGADR:	EQU	0C000H
; A=USR( TIME-TRAP É ±ÄÞÚ½ )
;	FNAME	"PARO-MUS.BIN"	;*BINHEAD*
	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"
;--------------------------------------

	ORG	ORGADR

	JP	PARODIUS_
	

;--------------------------------------
; WORK AREA
;--------------------------------------
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	00H,02H,0
;ROMSLT:	DB	1

SVW_SP:	DW	0
SV_HOOK:
	DS	5	;MAIN HOOK BACKUP

W_SBANK:
	DB	0

;--------------------------------------
PARODIUS_:
	INC	HL
	INC	HL
	LD	A,(HL)
	LD	(ROMSLT),A

	DI
	LD	(SVW_SP),SP

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
SETRAM:	LD	A,5
	LD	C,0
	LD	HL,4000H
	LD	B,80H
	CALL	TF_RAM

	LD	HL,MSET_R0
	LD	DE,661DH
	LD	BC,8
	LDIR

	LD	DE,621CH
	CALL	LD_SELSCC
	LD	DE,706CH
	CALL	LD_SELSCC
	LD	DE,70CDH
	CALL	LD_SELSCC

	LD	DE,624AH
	CALL	LD_RETSCC
	LD	DE,7073H
	CALL	LD_RETSCC
	LD	DE,70E6H
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

MSET_R0:
	LD	L,A
	LD	A,(W_SBANK)
	CP	L
	CALL	NZ,SL_BANK

SL_BANK:
	LD	DE,0620H
	LD	A,L
	LD	(W_SBANK),A
	OR	A
	JP	Z,SB_NO6
	LD	DE,0700H
SB_NO6:	LD	A,D
	LD	C,E
	LD	HL,0A000H
	LD	B,20H
	CALL	TF_RAM
	RET

;--------------------------------------
SEL_SCC:
	LD	A,0F1H	;?SCC SLOT
	CALL	WSLREG
	RET
RET_SCC:
	LD	A,0F3H	;?NOT SCC SLOT
	CALL	WSLREG
	RET

;--------------------------------------
PLAY:	LD	HL,0E000H
	LD	DE,0E001H
	LD	BC,0FFFH
	LD	(HL),0
	LDIR

	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	JP	RET_BAS

;--------------------------------------
PLAY_TRAP:
	JP	PLAY_TR

;--------------------------------------
	INCLUDE	"KONAMI8K.ASM"	;*FILE*
	INCLUDE	"PAROPLAY.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
ENDFL:
