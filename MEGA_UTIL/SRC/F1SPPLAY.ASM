;***************************************
;  in-game JUKEBOX for F-1 SPIRIT
;***************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
SYMBOL_FONT_COLOR:	EQU	90H
WORD_FONT_COLOR:	EQU	0F0H
;--------------------------------------

;SETWRT:	EQU	0171H
;WRTVRM:	EQU	0177H

; SOUND RUTINES
SMUSIC:		EQU	6000H
WMUSIC:		EQU	6AA5H
PMUSIC:		EQU	6422H
WRITE_SCC_REGS:	EQU	6CE9H

; SOUND WORK AREA
MUS_CTL:	EQU	0E160H	;BIT0:FADE OUT/BIT1:PAUSE
;MUS_NO:		EQU	0E161H	;01H-46H
MUS_NO:		EQU	CH_WORK1 ; CH1 WORKはBGMの番号が入ってる可能性が高い

CH_WORK1:	EQU	0E000H	;CHANNEL WORK*8 (2CH * 8)
CH_WORK2:	EQU	CH_WORK1 + (28H * 1)
CH_WORK3:	EQU	CH_WORK1 + (28H * 2)
CH_WORK4:	EQU	CH_WORK1 + (28H * 3)
CH_WORK5:	EQU	CH_WORK1 + (28H * 4)
CH_WORK6:	EQU	CH_WORK1 + (28H * 5)
CH_WORK7:	EQU	CH_WORK1 + (28H * 6)
CH_WORK8:	EQU	CH_WORK1 + (28H * 7)
PGSW_MIX:	EQU	0E176H	;(1) PSG MIXER (R#7)
SCCRFLG:	EQU	0E17EH	;(2) SCC REGISTER WRITE FLAG
SCCRWORK:	EQU	0E180H	;(10) SCC REGISTER WORK
SCCMXW:		EQU	0E18FH	;SCC CHANNEL ENABLE

;--------------------------------------
MUS_NO_MIN:	EQU	01H
MUS_NO_MAX:	EQU	46H
BGM_NO_MIN:	EQU	33H
BGM_NO_MAX:	EQU	43H

BGMNO_FADEOUT:	EQU	81H
BGMNO_FADEOFF:	EQU	80H
BGMNO_PAUSE:	EQU	83H
BGMNO_PAUSEOFF:	EQU	82H
BGMNO_STOP:	EQU	MUS_NO_MAX	;46H

;--------------------------------------
; LAYOUT
;--------------------------------------
P_CUR_X:	EQU	1
P_CUR_Y:	EQU	2
P_CUR_W:	EQU	6
NUM_SND_X:	EQU	8
NUM_SND_Y:	EQU	2
NUM_BGM_X:	EQU	8
NUM_BGM_Y:	EQU	4
TTL_BGM_X:	EQU	13
TTL_BGM_Y:	EQU	4
TTL_BGM_W:	EQU	17

;--------------------------------------
TCOUNT:	DB	0
WAITCT:	DB	0	;WAIT CNT

;--------------------------------------
SETMUSIC:	EQU	SMUSIC

;--------------------------------------
STOP_MUSIC:	EQU	INIT_MUSIC_WORK
;	LD	A,BGMNO_FADEOFF
;	CALL	SETMUSIC
;	CALL	PROC_MUSIC
;	LD	A,BGMNO_STOP
;	CALL	SETMUSIC
;	CALL	PROC_MUSIC
;	RET

;--------------------------------------
PROC_MUSIC:
	CALL	WMUSIC
	CALL	PMUSIC
	RET

;--------------------------------------
INIT_MUSIC_WORK:
	DI
	
	XOR	A
	LD	HL,MUS_CTL
	LD	(HL),A	;MUS_CTL
	INC	HL
	LD	(HL),A	;MUS_NO

	;RESET CHANNEL WORK
	LD	HL,CH_WORK1
	LD	DE,CH_WORK1+1
	LD	BC,10FFH
	LD	(HL),A
	LDIR

	;RESET SCC
	LD	A,0FFH
	LD	HL,SCCRFLG
	LD	(HL),A
	INC	HL
	LD	(HL),A
	CALL	WRITE_SCC_REGS

	;RESET PSG
	LD	A,0BFH		;42F7: 3E BF
	LD	(PGSW_MIX),A	;42F9: 32 76 E1
	LD	E,A		;42FC: 5F
	LD	A,07H		;42FD: 3E 07
	CALL	WRTPSG		;42FF: CD 93 00

	EI
	RET

;--------------------------------------
PLAY_END:
	CALL	STOP_MUSIC

	DI

	; MUTE PSG
	CALL	MUTE_PSG

	; MUTE SCC
	CALL	SEL_SCC
	XOR	A
	LD	(SCCR_CHENA),A
	CALL	RET_SCC

	JP	PLAY_R

;--------------------------------------
PLAY_SUB:
	LD	A,(MUS_NO)	;CURRENT BGM
	LD	(PLAYWK+0),A
	CALL	STOP_MUSIC

	LD	A,2	;CURSOR:EXIT
	LD	(PLAYWK+2),A

	LD	A,(PLAYWK+0)
	CALL	SETMUSIC

	LD	HL,2000H
	LD	(PAT_G_TB),HL
	LD	HL,0000H
	LD	(COLOR_TB),HL
	CALL	SETFONT

	LD	HL,TITLE_STR
	CALL	WR_MES

	EI

;--------------------------------------
L_PLAY:
	CALL	WR_CUR
	CALL	WR_PNUM
	CALL	WR_TITL
	XOR	A
	LD	(WAITCT),A
	EI
L_PLAYW:
	LD	DE,8FFH
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	CPL
	OR	A
	JP	Z,L_PLAYJ
	LD	A,(WAITCT)	;WAIT INTERVAL
	CP	20		;20/60 SEC
	JR	C,L_PLAYW
L_PLAYJ:
	EI
L_PLAY0:
	LD	DE,8FFH
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
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
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,P_STOP

	JP	L_PLAY0

;--------------------------------------
P_JUMPT:
	DW	P_RIGH,P_UP,P_DOWN,P_LEFT
	DW	P_DEL,P_INS,P_HOME,P_SPAC

;--------------------------------------
P_LCH:	POP	DE
	LD	A,(PLAYWK+2)
	CP	2
	JP	Z,L_PLAY
	LD	HL,PLAYWK+1
	PUSH	DE
	OR	A
	RET	Z
	DEC	HL
	RET

;--------------------------------------
P_INS:	LD	C,4
	JR	P_RIGH_
;--------------------------------------
P_RIGH:
	LD	C,1
P_RIGH_:
	CALL	P_LCH
	OR	A
	JR	NZ,P_ADD2
P_ADD:	LD	A,(HL)
	ADD	A,C
	CP	1
	JR	C,P_ADD_MIN
	CP	MUS_NO_MAX+1
	JR	C,J_PADD2
P_ADD_MIN:
	LD	A,MUS_NO_MIN
	JR	J_PADD2
P_ADD2:	LD	A,(HL)
	ADD	A,C
	CP	BGM_NO_MIN
	JR	C,J_PADD1
	CP	BGM_NO_MAX+1
	JR	C,J_PADD2
	LD	A,1
	JR	J_PADD2
J_PADD1:
	LD	A,BGM_NO_MIN
J_PADD2:
	LD	(HL),A
	JP	L_PLAY

;--------------------------------------
P_DEL:	LD	C,4
	JR	P_LEFT_
;--------------------------------------
P_LEFT:	LD	C,1
P_LEFT_:
	CALL	P_LCH
	OR	A
	JR	NZ,P_SUB2	;BGM
P_SUB:	LD	A,(HL)
	SUB	C
	CP	MUS_NO_MIN
	JR	C,P_SUB_MAX
	CP	MUS_NO_MAX+1
	JR	C,J_PSUB2
P_SUB_MAX:
	LD	A,MUS_NO_MAX
	JP	J_PSUB2
P_SUB2:	LD	A,(HL)
	SUB	C
	CP	BGM_NO_MAX+1
	JR	NC,J_PSUB1
	OR	A
	JR	Z,J_PSUB1
	CP	BGM_NO_MIN
	JR	NC,J_PSUB2
	LD	A,MUS_NO_MIN
	JR	J_PSUB2
J_PSUB1:
	LD	A,BGM_NO_MAX
J_PSUB2:
	LD	(HL),A
	JP	L_PLAY

;--------------------------------------
P_DOWN:	LD	A,(PLAYWK+2)
	DEC	A
	CP	255
	JR	NZ,L_PUD
	LD	A,2
	JR	L_PUD

;--------------------------------------
P_UP:	LD	A,(PLAYWK+2)
	INC	A
	CP	3
	JR	NZ,L_PUD
	XOR	A
L_PUD:	LD	(PLAYWK+2),A
	JP	L_PLAY


;--------------------------------------
P_HOME:	LD	A,BGMNO_FADEOUT
	CALL	SETMUSIC
	JP	L_PLAY

;--------------------------------------
P_STOP:
	CALL	STOP_MUSIC
	JP	L_PLAY

;--------------------------------------
P_SPAC:	LD	A,(PLAYWK+2)
	CP	2
	JP	Z,PLAY_END	;END JUKEBOX
	CALL	P_LCH
	LD	A,(HL)
	CP	MUS_NO_MIN
	JR	NC,P_SPAC0
	CP	MUS_NO_MAX+1
	JR	C,P_SPAC0
	LD	A,MUS_NO_MIN	;OUT OF RANGE
	LD	(HL),A
P_SPAC0:
	PUSH	AF
	LD	A,(PLAYWK+2)
	OR	A
	JP	Z,J_PL3	;SEなら止めない
;#if exists MUS_CTL
;WAIT_FO:
;	LD	A,(MUS_CTL)
;	BIT	0,A
;	JR	NZ,WAIT_FO
;#endif
	CALL	STOP_MUSIC
J_PL3:
	POP	AF
	CALL	SETMUSIC
WAIT_SPACE_RELEASE:
	LD	DE,0801H
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JR	Z,WAIT_SPACE_RELEASE
	JP	L_PLAY

;--------------------------------------
WR_PNUM:
	DI
	LD	HL,3800H+32*NUM_SND_Y+NUM_SND_X	;3848H
	CALL	SETWRT
	LD	A,(PLAYWK+1)
	CALL	WR_PNU_
	LD	HL,3800H+32*NUM_BGM_Y+NUM_BGM_X	;3888H
	CALL	SETWRT
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
	CALL	STR_NUM
	OUT	(VDP),A
	LD	A,B
	AND	15
	CALL	STR_NUM
	OUT	(VDP),A
	RET

;--------------------------------------
STR_NUM:
	OR	A
	DAA
	CP	10
	JR	C,STR_NUM_
	INC	A
STR_NUM_:
	ADD	A,30H
	RET

;--------------------------------------
WR_CUR:
	LD	HL,3800H+32*P_CUR_Y+P_CUR_X	;3841H
	LD	BC,300H
WR_CUR_L:
	LD	A,(PLAYWK+2)
	CP	C
	LD	A,0
	LD	D,0
	JR	NZ,WR_CUR_
	LD	A,'<'
	LD	D,'>'
WR_CUR_:
	DI
	CALL	WRTVRM
	LD	A,L
	ADD	A,P_CUR_W	;6
	LD	L,A
	LD	E,A
	LD	A,C
	CP	2
	JR	NZ,WR_CUR_2
	DEC	L
WR_CUR_2:
	LD	A,D
	CALL	WRTVRM
	EI
	LD	L,E
	INC	C
	LD	A,40H-P_CUR_W;	40H-6
	ADD	A,L
	LD	L,A
	DJNZ	WR_CUR_L
	RET

;--------------------------------------
PLAY_TR:
	DI
	CALL	RDVDP
	CALL	PROC_MUSIC

	LD	A,(TCOUNT)
	DEC	A
	LD	(TCOUNT),A

	CALL	RDVDP

	LD	A,(WAITCT)
	ADD	A,1
	SBC	A,0	; 255 = STOP
	LD	(WAITCT),A

	EI
	RET

;--------------------------------------
WR_TITL:
	DI
	LD	HL,3800H+32*TTL_BGM_Y+TTL_BGM_X ;388DH
	CALL	SETWRT
	LD	A,(PLAYWK)
	CALL	GET_TTL
	CALL	WR_MES_
	RET

;--------------------------------------
	INCLUDE	"MOJI-24.ASM"
	INCLUDE	"F1SPTITL.ASM"
