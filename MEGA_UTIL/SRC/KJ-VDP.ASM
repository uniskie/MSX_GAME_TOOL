;***************************
;  PUT KANJI 16 & VDP COMMAND
;      - SUB RUTINES -
;***************************
; "KJ-VDP.ASF"
YMMM:	EQU	0E0H
HMMM:	EQU	0D0H
LMMM:	EQU	090H
HMMC:	EQU	0F0H
LMMC:	EQU	0B0H
HMMV:	EQU	0C0H
LMMV:	EQU	080H
LINE:	EQU	070H
PSET:	EQU	050H
POINT:	EQU	040H
STOP:	EQU	000H
TIMP:	EQU	8
RSX:	EQU	32
RDX:	EQU	36

KJ_IO1:	EQU	0D8H
KJ_IO2:	EQU	0DAH

CL_OO_:	EQU	0FFH
CL_OX_:	EQU	0F0H
CL_XO_:	EQU	00FH
CL_XX_:	EQU	000H

ZENKA_X:	EQU	16
HANKA_X:	EQU	8

;ENTRY:
;  KANJI_RM  HL:CODE
;  KANJI_S   DE:STRENGTH ADDRESS
;  KANJI_C   A:COLOR
;   KANJI_PC
;   KANJI_P
;  VDP_COM
;  CE_WAIT,S_RESET

;=:	VDP resister's buffer for kanji
PR_MMC:	DW	0	;DX
	DW	0	;DY
	DW	0	;NX
	DW	16	;NY

;//
;  KANJI COLOR CHANGE RUTINE
;                           //
; A:COLOR
;  USE : AF
KANJI_C:
	PUSH	DE
	LD	(CLOR_XO+1),A
	LD	D,A
	RLCA
	RLCA
	RLCA
	RLCA
	LD	(CLOR_OX+1),A
	AND	0FH
	LD	E,A
	LD	A,D
	AND	0F0H
	OR	E
	LD	(CLOR_XX+1),A
	LD	A,D
	AND	0FH
	LD	D,A
	LD	A,(CLOR_OX+1)
	AND	0F0H
	OR	D
	LD	(CLOR_OO+1),A
	POP	DE
	RET
;//
;   KANJI (with ROM-CODE) PUT RUTINE
;                                 //
;//:	Check X Size //
;(:	HL:KANJI ROM-CODE)
KANJI_RM:
	PUSH	HL
	LD	A,ZENKA_X
	LD	DE,-960	;ÊÝ¶¸(A0H-DFH)
	ADD	HL,DE
	JP	C,KRM_CHK
	LD	DE,960-864
	ADD	HL,DE
	JP	C,SET_HNK
	LD	DE,864-96
	ADD	HL,DE
	JP	C,KRM_CHK
SET_HNK:
	LD	A,HANKA_X
KRM_CHK:
	LD	(PR_MMC+4),A	;NX write
	POP	HL
	JP	KANJI_PC

;//:	>> KANJI PUT
;  KANJI (with S-JIS) PUT RUTINE
;                               //
; (DE:ADDRESS) SHIFT-JIS >>  JIS >>KANJI CODE
; USE : HL,AF,DE,BC (ALL)

; CHECK CHRARACTER

KANJI_S:
	LD	A,HANKA_X
	LD	(PR_MMC+4),A
	LD	A,(DE)	;S-JIS(H)
; (ÊÝ¶¸ CHECK)
	LD	H,0
	CP	7FH+1
	JP	C,HANK	;ÊÝ¶¸ ASC(0)-(127)
	CP	0A0H+1
	JP	C,SJH_1
	CP	0DFH+1
	JP	NC,SJH_2
	LD	H,3	;ÊÝ¶¸ ASC(A0H)-(DFH)
	SUB	0A0H-60H-20H
HANK:	SUB	32
	LD	L,A
	PUSH	DE	;(ADDRESS)
	JP	KJC_ED
; (¾ÞÝ¶¸ CHECK)
SJH_1:	ADD	A,0B1H-71H
SJH_2:	SUB	0B1H
	ADD	A,A
	SUB	32-1
	LD	L,A	; L:JIS(H)-32 (A*2+1-32)

	LD	A,ZENKA_X
	LD	(PR_MMC+4),A

SJL_:	INC	DE
	LD	A,(DE)
	PUSH	DE	;(ADDRESS)
	CP	7FH+1	;(7FH:DEL)
	JP	C,SJL_1
	DEC	A
SJL_1:	INC	L
	CP	9EH
	JP	NC,SJL_2
	DEC	L
	ADD	A,7DH-1FH
SJL_2:	SUB	7DH+32

KJCODE:	LD	C,A
	LD	B,0
	LD	A,L
	RRCA
	RRCA
	RRCA
	LD	H,A
	AND	0E0H
	LD	L,A
	LD	A,H
	AND	1FH
	LD	H,A	;HL=L*32
	LD	D,H
	LD	E,L
	ADD	HL,HL	;HL=L*64
	ADD	HL,DE	;HL=L*(64+32) = L*96
	ADD	HL,BC	; HL= (JIS_H-32)*96 + (JIS_L-32)

	PUSH	HL
	LD	DE,-1536	;16*96
	ADD	HL,DE
	POP	HL
	JP	NC,KJC_ED
	LD	DE,-512
	ADD	HL,DE

KJC_ED:	CALL	KANJI_PC
	POP	DE
	INC	DE
	RET

;//:	Trancefer FONT to RAM //
;(:	HL:KANJI-CODE/PR_MMC:SET )
;(:	Out put KANJI CODE )
KANJI_PC:
	PUSH	HL
	POP	HL
	PUSH	HL
	LD	DE,-4096	;KANJI-ROM max
	ADD	HL,DE
	LD	C,KJ_IO1
	JP	NC,DAI1_K
	LD	C,KJ_IO2
	POP	DE
	JP	DAI1_K+1
DAI1_K:	POP	HL
KANJI_P:
	LD	A,L
	RLA
	RL	H
	RLA
	RL	H
	LD	A,3FH
	AND	L

	OUT	(C),A	;Write KANJI CODE Low6bit
	INC	C
	OUT	(C),H	;Write KANJI CODE Hi 6bit
;(:	Convert Font to bit-map )
	LD	HL,FONTAD
	LD	A,(PR_MMC+4)
	CP	HANKA_X
	JR	Z,FONTHK
	CALL	FONT_HX
	CALL	FONT_HX
	CALL	FONT_HX
	CALL	FONT_HX
	JP	SET_MMC
FONTHK:	CALL	FONT_HX
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	IN	A,(C)
	CALL	FONT_HX
	JP	SET_MMC
FONT_HX:
	LD	B,8
FONT_RD:
	IN	A,(C)	;A=Font data
	LD	D,4
CLOR_XX:
	LD	E,CL_XX_
	RLA
	JR	C,CLOR_OO
	RLA
	JP	NC,WTDOT
CLOR_XO:
	LD	E,CL_XO_
	JP	WTDOT
CLOR_OO:
	LD	E,CL_OO_
	RLA
	JR	C,WTDOT
CLOR_OX:
	LD	E,CL_OX_
WTDOT:	LD	(HL),E	;Write color code
	INC	HL
	DEC	D
	JP	NZ,CLOR_XX
	DJNZ	FONT_RD
	RET

;(:	Move command RAM to VRAM )

SET_MMC:
	DI

	PUSH	AF
	LD	A,(6)	;A=98H (VRAM PORT)
	INC	A	;A=99H (VDP REG PORT)
	LD	C,A	;C=99H (VDP REG PORT)
	POP	AF

;	LD	C,99H	;C=99H (VDP REG PORT)

	LD	A,36	;DATA:R#36(Inc)
	OUT	(C),A
	LD	A,17+80H	;R#17(¶Ý¾Âwrite set)
	OUT	(C),A
	LD	HL,PR_MMC	;VDP parameter address
	CALL	CE_WAIT
	INC	C	;C=9AH (PALETTE PORT)
	INC	C	;C=9BH (VDP ¶Ý¾Â PORT)
	OUTI	;DX L
	OUTI	;   H
	OUTI	;DY L
	OUTI	;   H
	OUTI	;NX L
	OUTI	;   H
	OUTI	;NY L
	OUTI	;   H
	LD	HL,FONTAD
	LD	B,(HL)	;CLR
	OUT	(C),B	;(DATA TOP)
	XOR	A
	OUT	(C),A	;ARG=0
	LD	A,HMMC
	OUT	(C),A	;VDP COMMAND
	DEC	C	;C=9AH (PALETTE PORT)
	DEC	C	;C=99H (VDP REG PORT)
;(:	Continue "MMC" )
	LD	A,44+80H	;DATA:R#44(Non-inc))
	OUT	(C),A
	LD	A,17+80H	;R#17(¶Ý¾Âwrite set)
	OUT	(C),A
	CALL	S_RESET
	EI
	INC	C	;C=9AH (PALETTE PORT)
	INC	C	;C=9BH (VDP ¶Ý¾Â PORT)
	INC	HL
	LD	A,(PR_MMC+4)
	CP	HANKA_X
	JR	Z,MMC_TP2
;(:	Output data from RAM to VRAM )
MMC_TP1:
	LD	DE,FONTAD+32
	LD	B,63+8
	CALL	MMCS1
	LD	HL,FONTAD+64
	LD	DE,FONTAD+96
	LD	B,64+8
	CALL	MMCSUB1
	RET
MMC_TP2:
	LD	B,63+16
	CALL	MMCS2
	RET
MMCSUB1:
	OUTI
MMCS1:	OUTI
	OUTI
	OUTI
	EX	DE,HL
	OUTI
	OUTI
	OUTI
	OUTI
	EX	DE,HL
	DJNZ	MMCSUB1
	RET
MMCSUB2:
	OUTI
MMCS2:	OUTI
	OUTI
	OUTI
	DJNZ	MMCSUB2
	RET
FONTAD:	DS	128


;//:	VDP COMMAND sub rutine //
;(:	HL:Parameter's Address )
;(:	B :Loop Count          )
;(:	A :Start Resister No.  )
VDP_COM:
	DI

	PUSH	AF
	LD	A,(6)	;A=98H (VRAM PORT)
	INC	A	;A=99H (VDP REG PORT)
	LD	C,A	;C=99H (VDP REG PORT)
	POP	AF

;	LD	C,99H	;C=99H (VDP REG PORT)

	OUT	(C),A
	LD	A,17+80H
	OUT	(C),A
	CALL	CE_WAIT
	INC	C	;C=9AH (PALETTE PORT)
	INC	C	;C=9BH (VDP ¶Ý¾Â PORT)
	OTIR
	DEC	C	;C=9AH (PALETTE PORT)
	DEC	C	;C=99H (VDP REG PORT)
	CALL	S_RESET
	EI
	RET

; //
; Wait for completing VDP Command
;                              //
CE_WAIT:
;	LD	C,99H	;C=99H (VDP REG PORT)
	LD	A,2
	OUT	(C),A
	LD	A,15+80H	;VDP Status set
	OUT	(C),A
CE_LOOP:
	IN	A,(C)
	AND	1
	JP	NZ,CE_LOOP
	RET

;(:	Reset status resister )
S_RESET:
;	LD	C,99H	;C=99H (VDP REG PORT)
	XOR	A
	OUT	(C),A
	LD	A,15+80H
	OUT	(C),A
	RET
