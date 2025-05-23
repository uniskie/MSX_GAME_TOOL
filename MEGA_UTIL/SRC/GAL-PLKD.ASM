;***************************************
;  DRAW RUTINES fo JUKEBOX (KANJI)
;  for Maze of GALIOUS
;***************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

BS_Y:	EQU	30H	;効果音 No. Y
BS_X:	EQU	58H	;効果音 No. X
BS_CUR_Y:	EQU	BS_Y		;カーソル原点 Y
BS_CUR_X:	EQU	BS_X - 14H	;カーソル原点 X
PNUM1_Y:	EQU	BS_Y		;SE番号 Y
PNUM1_X:	EQU	BS_X + 50H	;SE番号 X
PNUM2_Y:	EQU	BS_Y + 18H	;BGM番号 Y
PNUM2_X:	EQU	BS_X + 50H	;BGM番号 X
TITLE_Y:	EQU	0B8H
TITLE_X:	EQU	08H
;TITLE_CL:	EQU	01FH
TITLE_CL:	EQU	0CFH

;--------------------------------------
PLAY_TR_DISP:	EQU	SPRITE

;--------------------------------------
DRAW_PLAY_INIT:
	EI

	LD	HL,TITLE_STR
	CALL	WR_MES

	CALL	WR_CUR
	CALL	WR_PNUM1
	CALL	WR_PNUM2
	CALL	WR_TITL

	RET

;--------------------------------------
;DRAW_PLAY_LOOP:
;	RET

;--------------------------------------
DRAW_UPD_CUR:	EQU	WR_CUR

;--------------------------------------
DRAW_UPD_NUM1:
	CALL	WR_PNUM1
	RET

;--------------------------------------
DRAW_UPD_NUM2:
	CALL	WR_PNUM2
	CALL	WR_TITL
	RET

;--------------------------------------
;WR_MES_AT:
;	POP	HL
;	CALL	WR_MES
;	INC	HL
;	JP	(HL)

;--------------------------------------
WR_MES:	LD	A,(HL)
	CP	'|'
	RET	Z
	CP	'*'
	JP	Z,COLOR_
#IF exists _AILZ80ASM_
	CP	'\\'
#ELSE
	CP	'\'
#ENDIF
	JP	Z,LOCATE_
	CP	'^'
	JP	Z,ACPAGE_
	EX	DE,HL		;DE=STRING ADRS
	CALL	KANJI_S
	EX	DE,HL		;HL=STRING ADRS
	LD	A,(PR_MMC+4)
	LD	(ADD_X+1),A
	LD	A,(PR_MMC)
ADD_X:	ADD	A,00 	;?
	LD	(PR_MMC),A
	JP	NC,WR_MES
	LD	A,(PR_MMC+2)
	ADD	A,16
	LD	(PR_MMC+2),A
	JP	WR_MES

COLOR_:	INC	HL
	CALL	CHG_NSB
	CALL	KANJI_C
	JP	WR_MES
ACPAGE_:
	INC	HL
	CALL	CHG_NS
	LD	(BAPAGE-1),A
	JP	WR_MES
LOCATE_:
	INC	HL
	CALL	CHG_NSB
	LD	D,A
	CALL	CHG_NSB
	LD	E,A
	EX	DE,HL
	CALL	LOCATE	;L=X / H=Y
	EX	DE,HL
	JP	WR_MES

;--------------------------------------
; 2 chara to 8bit num (00 -> num)
CHG_NSB:
	CALL	CHG_NS
	RLCA
	RLCA
	RLCA
	RLCA
	LD	($+3+3+1),A
	CALL	CHG_NS
	OR	0 	;?
	RET

;--------------------------------------
; 1 char to 4bit num (0 -> num)
CHG_NS:	LD	A,(HL)
	INC	HL
	CP	'@'
	JP	C,$+3+2
	SUB	7
	SUB	30H
	AND	0FH
	RET

;--------------------------------------
WR_PNUM1:
	DI
	LD	A,(PLAYWK+1)
	LD	HL,PNUM1_X + PNUM1_Y * 100H
	CALL	LOCATE	;L=X / H=Y
	CALL	WR_PNU_
	EI
	RET
WR_PNUM2:
	DI
	LD	A,(PLAYWK+0)
	LD	HL,PNUM2_X + PNUM2_Y * 100H
	CALL	LOCATE	;L=X / H=Y
	CALL	WR_PNU_
	EI
	RET
WR_PNU_:
	LD	HL,NM_STR
	LD	B,A
	RRA
	RRA
	RRA
	RRA
	AND	15
	CALL	NMSET
	LD	A,B
	AND	15
	CALL	NMSET
	LD	HL,NM_STR_C
	CALL	WR_MES
	RET
NMSET:	OR	A
	DAA
	CP	10H
	JP	C,$+3+1
	INC	A
	ADD	A,'0'
	LD	(HL),A
	INC	HL
	RET
NM_STR_C:
	DB	'*CF'
NM_STR:	DB	'00|'

;--------------------------------------
LOCATE:	LD	IX,PR_MMC
	LD	(IX+0),L
	LD	(IX+1),0
BAPAGE:	LD	(IX+2),H
	LD	(IX+3),0
	RET

;--------------------------------------
WR_CUR:	LD	HL,BS_CUR_X + BS_CUR_Y * 100H
	LD	BC,300H
L_PL5:	CALL	LOCATE	;L=X / H=Y
	PUSH	HL
	PUSH	BC
	LD	A,(PLAYWK+2)
	CP	C
	LD	HL,COR_STR1
	JP	NZ,J_PL5 	;TO CALL WR_MES
	LD	HL,COR_STR2
J_PL5:	CALL	WR_MES
	POP	BC
	POP	HL
	INC	C
	LD	DE,1800H
	ADD	HL,DE
	DJNZ	L_PL5
	LD	A,0FH
	CALL	KANJI_C
	RET
COR_STR1:
	DB	'*C2□|'
COR_STR2:
	DB	'*23■|'


;--------------------------------------
WR_TITL:
	LD	A,TITLE_CL
	CALL	KANJI_C
	DI
	LD	HL,TITLE_X + TITLE_Y * 100H
	CALL	LOCATE	;L=X / H=Y
	LD	A,(PLAYWK)
	LD	DE,0
	LD	DE,MUS_TIT
	CP	0FBH
	JP	C,$+3+3+2
	SUB	0FBH-16H
	JP	WR_TIT0
	SUB	80H
	CP	16H
	JP	C,$+3+1
	XOR	A
WR_TIT0:
	LD	L,A
	LD	H,0
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL
	ADD	HL,HL 	;HL=(A*32)
	ADD	HL,DE
	CALL	WR_MES
	EI
	LD	A,0FH
	CALL	KANJI_C
	RET

;**************************************
; SPRITE ANIMATION
;**************************************
;--------------------------------------
; SPRITE TABLE
SPRATR:	EQU	7600H
SPR_TB:	EQU	0D000H
SP_PARA:	EQU	0D080H

;--------------------------------------
SPRITE:	LD	B,32
	LD	HL,SP_PARA
	EXX
	LD	HL,SPR_TB
	EXX
L_SP_P:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	INC	HL
	LD	A,(HL)
	DEC	A
	LD	(HL),A
	INC	HL
	OR	A
	JP	Z,CH_SPR

	LD	DE,0
	JP	ADD_SPR

CH_SPR:	LD	A,(HL)
	DEC	HL
	LD	(HL),A
	INC	HL
ADD_SPR:
	INC	HL
	PUSH	DE
	EXX
	POP	DE
	LD	A,(HL)
	ADD	A,E
	CP	20H
	JP	NC,SPR_Y1
	LD	A,0A0H-1
SPR_Y1:	CP	0A0H
	JP	C,SPR_Y
	LD	A,20H
SPR_Y:	LD	(HL),A
	INC	HL
	LD	A,(HL)
	ADD	A,D
	LD	(HL),A
	INC	HL
	INC	HL
	INC	HL
	EXX
	DJNZ	L_SP_P
; WRITE TABLE TO VRAM

	LD	HL,SPRATR
	LD	A,1
	OUT	(VDP+1),A
	LD	A,14+80H
	OUT	(VDP+1),A
	LD	A,L
	OUT	(VDP+1),A
	LD	A,H
	AND	3FH
	OR	40H
	OUT	(VDP+1),A
;  SET READY
	LD	HL,SPR_TB
	LD	BC,VDP+8000H
	OTIR
	RET

