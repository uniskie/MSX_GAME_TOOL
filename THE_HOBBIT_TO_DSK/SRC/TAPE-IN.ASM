;*** TAPE FILES ***

TAPION:	EQU	00E1H
TAPIN:	EQU	00E4H
TAPIOF:	EQU	00E7H
STMOTR:	EQU	00F3H
CHPUT:	EQU	00A2H
BEEP:	EQU	00C0H

VDP:	EQU	98H


	FNAME	"TAPE-IN.BIN"	;*BINHEAD*
;--> BIN FILE HEADER -->
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;<-- BIN FILE HEADER <--
;

ORGADR:	EQU	0D000H
	ORG	ORGADR

START:	LD	(RET_SP+1),SP
	CALL	TAPION
	LD	B,16
	LD	HL,WORK_T
L_HEAD:	PUSH	HL
	PUSH	BC
	CALL	TAPIN
	POP	BC
	POP	HL
	JP	C,ERROR
	LD	(HL),A
	INC	HL
	DJNZ	L_HEAD

	XOR	A
	CALL	STMOTR

	LD	A,(WORK_T)

CHECK:	CP	0D3H
	JP	Z,CSVFIL
	CP	0EAH
	JP	Z,ASCFIL
	CP	0D0H
	JP	Z,BSVFIL
	LD	A,(0F7F8H)
	OR	A
	JP	NZ,CHECK

; unknown FORMAT

	LD	HL,D_UKN
	CALL	PUTMES
	CALL	VSET_H
	LD	A,1
	CALL	STMOTR
UKN_L:	CALL	VSET_D
	JP	NC,UKN_L
	JP	RET_T

; CSAVE FILE

CSVFIL:	LD	HL,D_CSV
	CALL	PUTMES
	CALL	FILNAM
	CALL	VSET_H
	PUSH	DE
	CALL	TAPION
	JP	C,ERROR
	POP	DE
CSV_L:	CALL	VSET_D
	JP	C,ERROR
	CP	0
	JP	NZ,CSV_J
	DEC	B
	JP	Z,RET_T
	JP	CSV_L
CSV_J:	LD	B,7
	JP	CSV_L

; ASCII FILE

ASCFIL:	LD	HL,D_ASC
	CALL	PUTMES
	CALL	FILNAM
	CALL	VSET_H
ASC_L0:	PUSH	DE
	CALL	TAPION
	JP	C,ERROR
	POP	DE
	LD	B,0
ASC_L1:	CALL	VSET_D
	JP	C,ERROR
	CP	1AH
	JP	Z,RET_T
	DJNZ	ASC_L1

; BSAVE FILE

BSVFIL:	LD	HL,D_BSV
	CALL	PUTMES
	CALL	FILNAM
	CALL	VSET_H
	PUSH	DE
	CALL	TAPION
	JP	C,ERROR
	POP	DE

	LD	HL,D_BSVA
	LD	A,6
L_BSV0:	PUSH	AF
	CALL	VSET_D
	JP	C,ERROR
	LD	(HL),A
	INC	HL
	POP	AF
	DEC	A
	JP	NZ,L_BSV0

	LD	BC,(D_BSVA)
	LD	HL,(D_BSVA+2)
	OR	A
	SBC	HL,BC
	INC	HL
BSV_L:	CALL	VSET_D
	JP	C,ERROR_
	DEC	HL
	LD	A,L
	OR	H
	JP	NZ,BSV_L
	CALL	PUTADR
	JP	RET_T

; RETURN to BASIC

RET_T:	LD	HL,D_ENDM
	CALL	PUTMES
	LD	A,D
	CALL	PUTBYT
	LD	A,E
	CALL	PUTBYT
	LD	HL,D_ADRE
	CALL	PUTMES

	CALL	TAPIOF
	RET


; HEAD DATA SET for VRAM

VSET_H:	LD	A,4
	OUT	(VDP+1),A
	LD	A,14+80H
	OUT	(VDP+1),A
	XOR	A
	OUT	(VDP+1),A
	LD	A,40H
	OUT	(VDP+1),A

	LD	HL,WORK_T
	LD	B,16
	LD	C,VDP
	OTIR

	LD	DE,16
	RET

; READ DATA & SET for VRAM

VSET_D:	INC	DE
	PUSH	HL
	PUSH	DE
	PUSH	BC
	CALL	TAPIN
	OUT	(VDP),A
	POP	BC
	POP	DE
	POP	HL
	RET

; PUT MESSAGE

PUTMES:	LD	A,(HL)
	AND	A
	RET	Z
	CALL	CHPUT
	INC	HL
	JP	PUTMES

; ERROR !

ERROR_:	CALL	PUTADR
ERROR:	LD	HL,D_EROR
	CALL	PUTMES
	XOR	A
RET_SP:	LD	SP,0	;?
	CALL	STMOTR
	EI
	RET

; PUT FILENAME

FILNAM:	LD	HL,D_FILN
	CALL	PUTMES
	LD	HL,WORK_T+10
	CALL	PUTMES
	RET

; PUT ADDRESS (BLOAD)

PUTADR:	PUSH	HL
	PUSH	DE
	LD	HL,D_ADRM
	LD	DE,D_BSVA
	LD	B,3
L_PADR:	CALL	PUTMES
	INC	HL
	EX	DE,HL
	LD	C,(HL)
	INC	HL
	LD	A,(HL)
	INC	HL
	CALL	PUTBYT
	LD	A,C
	CALL	PUTBYT
	EX	DE,HL
	PUSH	HL
	LD	HL,D_ADRE
	CALL	PUTMES
	POP	HL
	DJNZ	L_PADR
	POP	DE
	POP	HL
	RET

; PUT 1 BITE

PUTBYT:	PUSH	AF
	PUSH	BC
	LD	B,A
	RRA
	RRA
	RRA
	RRA
	AND	15
	CALL	PUTVAL
	LD	A,B
	AND	15
	CALL	PUTVAL
	POP	BC
	POP	AF
	RET

PUTVAL:	OR	A
	DAA
	CP	10
	JP	C,$+3+1
	INC	A
	ADD	A,30H
	CALL	CHPUT
	RET

; DATA AREA

WORK_T:	DS	16
	DB	0DH,0AH,0
D_BSVA:	DS	6
D_ADRM:	DB	'HEAD:'	;*DM*
	DB	0
	DB	' END:'	;*DM*
	DB	0
	DB	'  GO:'	;*DM*
	DB	0
D_ADRE:	DB	'H',0DH,0AH,0

D_FILN:	DB	'FILENAME:'	;*DM*
	DB	0
D_CSV:	DB	'- CLOAD -'	;*DM*
	DB	0DH,0AH,0
D_ASC:	DB	'- ASCII -'	;*DM*
	DB	0DH,0AH,0
D_BSV:	DB	'- BLOAD -'	;*DM*
	DB	0DH,0AH,0
D_UKN:	DB	'- OTHER DATA -'	;*DM*
	DB	0DH,0AH,0
D_EROR:	DB	'_ TAPE READ ERROR !!'	;*DM*
	DB	07H,0DH,0AH,0
D_ENDM:	DB	'DATA:VRAM 10000H-1'	;*DM*
	DB	0
ENDFL:	;
