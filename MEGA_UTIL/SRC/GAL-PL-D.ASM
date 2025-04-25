;***************************************
;  DRAW RUTINES fo in-game JUKEBOX
;  for Maze of GALIOUS
;***************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
;PLAY_TR_DISP:	EQU	SPRITE

;--------------------------------------
DRAW_PLAY_INIT:
	CALL	SETFONT

	LD	HL,TITLE_STR
	CALL	WR_MES

	RET

;--------------------------------------
DRAW_PLAY_LOOP:
	CALL	WR_CUR
	CALL	WR_PNUM
	CALL	WR_TITL
	RET

;--------------------------------------
;DRAW_UPD_CUR:	EQU	WR_CUR

;--------------------------------------
;DRAW_UPD_NUM1:
;	CALL	WR_PNUM1
;	RET

;--------------------------------------
;DRAW_UPD_NUM2:
;	CALL	WR_PNUM2
;	CALL	WR_TITL
;	RET

;--------------------------------------
WR_MES_AT:
	POP	HL
	CALL	WR_MES
	JP	(HL)

WR_MES:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	DI
	CALL	NSTWRT
	DI
	EX	DE,HL
	INC	HL
WR_MES_:
	LD	A,(HL)
	CP	'¡'
	JP	Z,J_PL4
	CP	'A'
	JR	C,.@1
	SUB	7
.@1	SUB	15+32
	OUT	(VDP),A
	INC	HL
	JP	WR_MES_
J_PL4:	INC	HL
	RET

;--------------------------------------
WR_PNUM:
	DI
	LD	HL,3849H
	CALL	NSTWRT
	LD	A,(PLAYWK+1)
	CALL	WR_PNU_
	LD	HL,3889H
	CALL	NSTWRT
	LD	A,(PLAYWK+0)
	CALL	WR_PNU_
	EI
	RET
WR_PNU_:
	LD	B,A
	RRA
	RRA
	RRA
	RRA
	AND	15
	INC	A
	OUT	(VDP),A
	LD	A,B
	AND	15
	INC	A
	OUT	(VDP),A
	RET

;--------------------------------------
WR_CUR:	LD	HL,3841H
	LD	BC,300H
L_PL5:	LD	A,(PLAYWK+2)
	CP	C
	LD	A,0
	LD	D,0
	JR	NZ,.@1
	LD	A,44H
	LD	D,45H
.@1:	DI
	CALL	NWRVRM
	LD	A,L
	ADD	A,6
	LD	L,A
	LD	E,A
	LD	A,2
	CP	C
	JR	NZ,.@2
	DEC	L
.@2:	LD	A,D
	CALL	NWRVRM
	EI
	LD	L,E
	INC	C
	LD	A,40H-6
	ADD	A,L
	LD	L,A
	DJNZ	L_PL5
	RET

;--------------------------------------
SETFONT:
	; SETFONT? -> DI-EI
	CALL	SELFONTBANK	;BANK D,E,F
	LD	DE,9AD3H
	LD	HL,2008H
	CALL	SETFONT0
	LD	DE,9B24H
	LD	HL,2058H
	CALL	SETFONT0
	LD	A,0F0H
	LD	HL,0008H
	LD	BC,0120H
	CALL	BIGFIL
	CALL	41B7H	;BANK A,B,C
	LD	IX,D_FDAT
	JP	SETFONT1
;--------------------------------------
D_FDAT:	
;	DB	7,99H,63H,25H,63H,65H,0	;6000H + 2000H*bank10
	DB	4,99H,63H,25H,63H,65H,0
;--------------------------------------
WR_TITL:
	DI
	LD	HL,388FH
	CALL	NSTWRT
	LD	D,0
	LD	A,(PLAYWK)
	CP	0FBH
	JP	C,J_WTIT1
	SUB	0FBH-16H
	JP	J_WTIT2

J_WTIT1:
	SUB	80H
	CP	16H
	JP	C,J_WTIT2
	XOR	A

J_WTIT2:
	RLA
	RLA
	RLA
	RLA
	JP	NC,J_WTIT3
	INC	D
J_WTIT3:
	AND	0F0H
	LD	E,A
	LD	HL,MUS_TIT
	ADD	HL,DE
	CALL	WR_MES_
	RET

