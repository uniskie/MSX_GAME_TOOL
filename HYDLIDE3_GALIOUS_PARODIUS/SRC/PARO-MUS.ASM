;***************************
;    PARODIUS  SOUND-BOX
;***************************
; A=USR( TIME-TRAP � ���ڽ )
	FNAME	"PARO-MUS.BIN"	;*BINHEAD*
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;
;
ENASLT:	EQU	0024H
RSLREG:	EQU	0138H
WSLREG:	EQU	013BH
DACINT:	EQU	0F7F8H
H_KEYI:	EQU	0FD9AH
H_TIMI:	EQU	0FD9FH
RAMPG0:	EQU	0F341H
EXPTBL:	EQU	0FCC1H
;
PSGIOA:	EQU	0A0H
PSGIOW:	EQU	PSGIOA+1
;
W_BANK:	EQU	0F0F1H
BANK1:	EQU	7000H
BANK2:	EQU	9000H
BANK3:	EQU	0B000H
;
ORGADR:	EQU	0C000H
	ORG	ORGADR
;
	JP	PARODIUS_
;
PAR_MUS:	;
	DB	00H,02H,0
ROMSLT:	DB	1
T_COUNT:	;
	DB	0
SVW_SP:	DW	0
;
PARODIUS_:	;
	DI
	LD	(SVW_SP),SP
;
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
;
	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR
;
;	IM	1
	LD	SP,0D300H	;(0F378H)
;
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT
	LD	A,(RAMPG0+1)
	LD	H,40H
	CALL	ENASLT
;
	CALL	RSLREG
	LD	(SEL_SCC+1),A
	LD	A,3FH
	LD	(9000H),A
;
	LD	A,(RAMPG0+2)
	LD	H,80H
	CALL	ENASLT
	CALL	RSLREG
	LD	(RET_SCC+1),A
	CALL	SETRAM
;
	LD	HL,PLAY_TR	;COMMON
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A
;
	JP	PLAY
;
;
;
RET_BAS:	;
	DI
;
	LD	HL,SV_HOOK
	LD	DE,H_KEYI
	LD	BC,5
	LDIR
;
	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT
	LD	A,(RAMPG0+2)
	LD	H,80H
	CALL	ENASLT
;
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
;
	LD	SP,(SVW_SP)	;COMMON
;	IM	0
	EI
;
	RET
;
SETRAM:	LD	A,5
	LD	C,0
	LD	HL,4000H
	LD	B,80H
	CALL	TF_RAM
;
	LD	HL,MSET_R0
	LD	DE,661DH
	LD	BC,8
	LDIR
;
	LD	DE,621CH
	CALL	LD_SELSCC
	LD	DE,706CH
	CALL	LD_SELSCC
	LD	DE,70CDH
	CALL	LD_SELSCC
;
	LD	DE,624AH
	CALL	LD_RETSCC
	LD	DE,7073H
	CALL	LD_RETSCC
	LD	DE,70E6H
	CALL	LD_RETSCC
;
	RET
;
LD_SELSCC:	;
	LD	HL,SEL_SCC
	LD	BC,5
	LDIR
	RET
LD_RETSCC:	;
	LD	HL,RET_SCC
	LD	BC,5
	LDIR
	RET
;
MSET_R0:	;
	LD	L,A
	LD	A,(W_SBANK)
	CP	L
	CALL	NZ,SL_BANK
;
SL_BANK:	;
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
;
W_SBANK:	;
	DB	0
;
SEL_SCC:	;
	LD	A,0F1H	;?SCC SLOT
	CALL	WSLREG
	RET
RET_SCC:	;
	LD	A,0F3H	;?NOT SCC SLOT
	CALL	WSLREG
	RET
;
;
W_SLREG:	;
	DB	0
SV_HOOK:	;
	DS	5
;
;
CGPNT:	EQU	0F91FH
BASFNT:	EQU	CGPNT+1
FILVRM:	EQU	016BH
SETWRT:	EQU	0171H
WRTVRM:	EQU	0177H
;
IMUSIC:	EQU	6000H
SMUSIC:	EQU	6003H
PMUSIC:	EQU	6006H
MUS_NO:	EQU	0E13BH
SCCMIX:	EQU	0E1F3H
;
PLAY:	LD	HL,0E000H
	LD	DE,0E001H
	LD	BC,0FFFH
	LD	(HL),0
	LDIR
;
	LD	A,2
	LD	(PAR_MUS+2),A
	LD	A,30H
	LD	(PAR_MUS+0),A
	CALL	IMUSIC
	EI
	LD	HL,2000H
	LD	(PAT_G_TB),HL
	LD	HL,0000H
	LD	(COLOR_TB),HL
	CALL	SETFONT
	LD	A,30H
	CALL	SETMUSIC
;
	CALL	WR_MES_AT
	DW	3800H
	DB	'XWW PARODIUS :SOUND-BOX WWWWWWWY'	;*DM*
	DB	'V                              V'	;*DM*
	DB	'V SOUND -00-     NOW PLAYING   V'	;*DM*
	DB	'V             XWWWWWWWWWWWWWWWYV'	;*DM*
	DB	'V MUSIC -00-  V               VV'	;*DM*
	DB	'V             ZWWWWWWWWWWWWWWW[V'	;*DM*
	DB	'V EXIT         (STOP):STOP-BGM V'	;*DM*
	DB	'ZWWWWWWWWWWWWWW(HOME):FADE-OUT ['	;*DM*
	DB	'�'
;
	EI
	JP	L_PLAY
;
;
PLAY_R:	DI
	LD	A,7
	OUT	(PSGIOA),A	;COMMON
	LD	A,0BFH
	OUT	(PSGIOW),A	;COMMON
;
	CALL	SEL_SCC
	XOR	A
	LD	(988FH),A
	CALL	RET_SCC
;
	JP	RET_BAS
;
;
L_PLAY:	XOR	A
	LD	(WAITCT),A
	CALL	WR_PNO
	CALL	WR_PNUM
	CALL	WR_TITL
	EI
L_PLAYW:	;
	LD	DE,8FFH
	CALL	KEYIN
	CPL
	OR	A
	JP	Z,L_PLAYJ
	LD	A,(WAITCT)	;WAIT INTERVAL
	CP	20	;20/60 SEC
	JR	C,L_PLAYW
L_PLAYJ:	;
	EI
L_PLAY0:	;
	LD	DE,8FFH
	CALL	KEYIN
	LD	HL,P_JUMPT
	LD	B,8
L_PL0:	RLA
	JP	C,J_PL0
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	JP	(HL)
J_PL0:	INC	HL
	INC	HL
	DJNZ	L_PL0
	LD	DE,0710H	;STOP
	CALL	KEYIN
	JP	Z,P_STOP
	JP	L_PLAY0
P_JUMPT:	;
	DW	P_RIGH,P_UP,P_DOWN,P_LEFT
	DW	P_DEL,P_INS,P_HOME,P_SPAC
;
P_LCH:	POP	DE
	LD	A,(PAR_MUS+2)
	CP	2
	JP	Z,L_PLAY
	LD	HL,PAR_MUS+1
	PUSH	DE
	OR	A
	RET	Z
	DEC	HL
	RET
;
P_INS:	LD	C,4
	JP	$+5
P_RIGH:	LD	C,1
	CALL	P_LCH
	OR	A
	JP	NZ,P_ADD2
P_ADD:	LD	A,(HL)
	ADD	A,C
	AND	127
	LD	(HL),A
	JP	L_PLAY
P_ADD2:	LD	A,(HL)
	ADD	A,C
	CP	30H
	JP	C,J_PADD2-2
	CP	3EH
	JP	C,J_PADD2
	LD	A,1
	JP	J_PADD2
	LD	A,30H
J_PADD2:	;
	LD	(HL),A
	JP	L_PLAY
;
P_DEL:	LD	C,4
	JP	$+5
P_LEFT:	LD	C,1
	CALL	P_LCH
	OR	A
	JP	NZ,P_SUB2
P_SUB:	LD	A,(HL)
	SUB	C
	AND	127
	LD	(HL),A
	JP	L_PLAY
P_SUB2:	LD	A,(HL)
	SUB	C
	CP	3EH
	JP	NC,J_PSUB2-2
	OR	A
	JP	Z,J_PSUB2-2
	CP	30H
	JP	NC,J_PSUB2
	LD	A,01H
	JP	J_PSUB2
	LD	A,3DH
J_PSUB2:	;
	LD	(HL),A
	JP	L_PLAY
;
P_DOWN:	LD	A,(PAR_MUS+2)
	DEC	A
	CP	255
	JP	NZ,L_PUD
	LD	A,2
	JP	L_PUD
;
P_UP:	LD	A,(PAR_MUS+2)
	INC	A
	CP	3
	JP	NZ,L_PUD
	XOR	A
L_PUD:	LD	(PAR_MUS+2),A
	JP	L_PLAY
;
P_HOME:	LD	A,81H
	CALL	SETMUSIC
	JP	L_PLAY
;
P_STOP:	LD	A,01H
	CALL	SETMUSIC
	JP	L_PLAY
;
P_SPAC:	LD	A,(PAR_MUS+2)
	CP	2
	JP	Z,PLAY_R
	CALL	P_LCH
	LD	C,(HL)
	JP	Z,J_PL3
	LD	A,1
	CALL	SETMUSIC
	LD	(T_COUNT),A
	LD	A,(T_COUNT)
	OR	A
	JP	NZ,$-1-3
	LD	A,80H
	CALL	SETMUSIC
	LD	A,87H
	CALL	SETMUSIC
J_PL3:	LD	A,C
	CALL	SETMUSIC
	LD	DE,0801H
	CALL	KEYIN
	JP	Z,$-6
	JP	L_PLAY
;
WR_MES_AT:	;
	POP	HL
	CALL	WR_MES
	INC	HL
	JP	(HL)
;
WR_MES:	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	EX	DE,HL
	DI
	CALL	SETWRT
	DI
	EX	DE,HL
	INC	HL
WR_MES_:	;
	LD	A,(HL)
	CP	'�'
	RET	Z
	CP	1
	JP	NZ,J_PL4
	INC	HL
	LD	A,(HL)
	SUB	40H
J_PL4:	OUT	(VDP),A
	INC	HL
	JP	WR_MES_
;
WR_PNUM:	;
	DI
	LD	HL,3849H
	CALL	SETWRT
	LD	A,(PAR_MUS+1)
	CALL	WR_PNU_
	LD	HL,3889H
	CALL	SETWRT
	LD	A,(PAR_MUS+0)
	CALL	WR_PNU_
	EI
	RET
WR_PNU_:	;
	LD	B,A
	RRA
	RRA
	RRA
	RRA
	AND	15
	CALL	STR_NUM
	OUT	(VDP),A
	LD	A,B
	AND	15
	CALL	STR_NUM
	OUT	(VDP),A
	RET
;
STR_NUM:	;
	OR	A
	DAA
	CP	10
	JP	C,$+3+1
	INC	A
	ADD	A,30H
	RET
;
WR_PNO:	LD	HL,3841H
	LD	BC,300H
L_PL5:	LD	A,(PAR_MUS+2)
	CP	C
	LD	A,0
	LD	D,0
	JP	NZ,$+7	;TO LD D,A
	LD	A,'<'
	LD	D,'>'
	DI
	CALL	WRTVRM
	LD	A,L
	ADD	A,6
	LD	L,A
	LD	E,A
	LD	A,2
	CP	C
	JP	NZ,$+4
	DEC	L
	LD	A,D
	CALL	WRTVRM
	EI
	LD	L,E
	INC	C
	LD	A,40H-6
	ADD	A,L
	LD	L,A
	DJNZ	L_PL5
	RET
;
;
PLAY_TR:	;
	DI
	CALL	013EH
	CALL	PMUSIC
;
	LD	A,(T_COUNT)
	DEC	A
	LD	(T_COUNT),A
;
	CALL	013EH
;
	LD	A,(WAITCT)
	ADD	A,1
	SBC	A,0	; 255 = STOP
	LD	(WAITCT),A
;
	EI
	RET
;
WAITCT:	DB	0	;WAIT CNT
;
SETMUSIC:	;
	PUSH	AF
	PUSH	BC
	PUSH	DE
	PUSH	HL
	DI
	CALL	SMUSIC
	EI
	POP	HL
	POP	DE
	POP	BC
	POP	AF
	RET
;
SVPHOOK:	;
	DS	5
;
PAT_G_TB:	;
	DW	0
COLOR_TB:	;
	DW	0
;
SETFONT:	;
	DI
	LD	A,(PAT_G_TB+1)
	AND	3FH	;BIT 8-11
	OR	40H	;WRITE
	LD	C,A
	XOR	A
	CALL	VSET
	LD	HL,(BASFNT)
	LD	BC,800H
L_SFONT:	;
	LD	A,(HL)
	INC	HL
	LD	E,A
	SRL	E
	AND	0E0H
	OR	E
	OUT	(VDP),A
	DEC	C
	JP	NZ,L_SFONT
	DJNZ	L_SFONT
;
	LD	HL,(COLOR_TB)
	LD	BC,100H
	LD	A,80H
	CALL	FILVRM
	DI
;
	LD	A,(COLOR_TB+1)
	ADD	A,1+40H
	LD	C,A
	XOR	A
	CALL	VSET
	LD	C,0E0H
L_SFNT0:	;
	LD	B,4
	LD	A,0F0H
L_SFNT1:	;
	OUT	(VDP),A
	DJNZ	L_SFNT1
	LD	B,4
	LD	A,0E0H
L_SFNT2:	;
	OUT	(VDP),A
	DJNZ	L_SFNT2
	DEC	C
	JP	NZ,L_SFNT0
;
	LD	DE,01E0H
	LD	HL,(COLOR_TB)
	ADD	HL,DE
	LD	BC,0020H
	LD	A,80H
	CALL	FILVRM
	DI
	RET
;
;
WR_TITL:	;
	DI
	LD	HL,388FH
	CALL	SETWRT
	LD	D,0
	LD	A,(PAR_MUS)
	CP	30H
	JP	C,J_WTIT1-2
	CP	3EH
	JP	C,J_WTIT1
	LD	A,3EH
;
J_WTIT1:	;
	SUB	30H
	RLA
	RLA
	RLA
	RLA
	JP	NC,J_WTIT3
	INC	D
J_WTIT3:	;
	AND	0F0H
	LD	E,A
	LD	HL,MUS_TIT
	ADD	HL,DE
	CALL	WR_MES_
	RET
;
;
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
	INCLUDE	"PAROTITL.ASM"	;*FILE*
ENDFL:	;
