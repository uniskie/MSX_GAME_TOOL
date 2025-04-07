;***************************
; KONAMI 8K MEGAROM UTIL
;***************************

;BIOS LABELS for GAME UTILS
;	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; KONAMI MEGA-ROM BANK
;--------------------------------------
W_BANK:	EQU	0F0F1H
BANK1:	EQU	7000H	;6000HÇÃèÍçáÇ‡Ç†ÇÈ
BANK2:	EQU	9000H	;8000HÇÃèÍçáÇ‡Ç†ÇÈ
BANK3:	EQU	0B000H	;A000HÇÃèÍçáÇ‡Ç†ÇÈ

;--------------------------------------
; KONAMI SCC
;--------------------------------------
SCCMIX:	EQU	988FH

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
	LD	BC,(4002H)
	OR	A
	SBC	HL,BC
	EX	DE,HL

	LD	BC,(ROMSLT)
	LD	B,0
	RET

