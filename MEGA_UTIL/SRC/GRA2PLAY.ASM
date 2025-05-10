;***************************************
;  in-game JUKEBOX for GRADIUS2
;***************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
SYMBOL_FONT_COLOR:	EQU	30H
WORD_FONT_COLOR:	EQU	0F0H
;--------------------------------------

;SETWRT:	EQU	0171H
;WRTVRM:	EQU	0177H

; SOUND RUTINES
IMUSIC:		EQU	6000H
SMUSIC:		EQU	6480H
PMUSIC:		EQU	6934H

; SOUND WORK AREA
MUS_CTL:	EQU	0E190H	;bit0:FADE OUT / bit4:FADE IN / bit1:PAUSE
;MUS_NO:		EQU	0E191H
MUS_NO:		EQU	CH_WORK8 ; CH8 WORKはBGMの番号が入ってる可能性が高い

CH_WORK1:	EQU	0E000H	;CHANNEL WORK (28H * 8 = 140H)
CH_WORK2:	EQU	CH_WORK1 + (28H * 1)
CH_WORK3:	EQU	CH_WORK1 + (28H * 2)
CH_WORK4:	EQU	CH_WORK1 + (28H * 3)
CH_WORK5:	EQU	CH_WORK1 + (28H * 4)
CH_WORK6:	EQU	CH_WORK1 + (28H * 5)
CH_WORK7:	EQU	CH_WORK1 + (28H * 6)
CH_WORK8:	EQU	CH_WORK1 + (28H * 7)
PGSW_MIX:	EQU	0E1A6H	;(1) PSG MIXER (R#7)
SCCRFLG:	EQU	0E1AEH	;(2) SCC REGISTER WRITE MASK
SCCRWORK:	EQU	0E1B0H	;(10) SCC REGISTER WORK
SCCMXW:		EQU	0E1BFH	;(1)

MUS_MUTEX:	EQU	0E1D4H	;PMUSIC MUTEX (VSYNC割り込み再入防止カウンタ)

;WRITE_SCC_REGS	EQU	71AEH	

;--------------------------------------
MUS_NO_MIN:	EQU	01H
MUS_NO_MAX:	EQU	43H
BGM_NO_MIN:	EQU	2BH
BGM_NO_MAX:	EQU	43H

BGMNO_FADEOFF:	EQU	0F0H
BGMNO_FADEOUT:	EQU	0F1H
BGMNO_PAUSE:	EQU	0F3H
BGMNO_PAUSEOFF:	EQU	0F2H
;BGMNO_STOP:	EQU	BGM_NO_MAX	;演奏停止を完全には行えない

;--------------------------------------
TCOUNT:	DB	0
WAITCT:	DB	0	;WAIT CNT

;--------------------------------------
SETMUSIC:	EQU	SMUSIC

;--------------------------------------
STOP_MUSIC:	EQU	INIT_MUSIC_WORK
;	DI
;
;	LD	A,(MUS_CTL)
;	BIT	1,A
;	LD	A,BGMNO_PAUSEOFF
;	CALL	NZ,SETMUSIC
;
;	LD	A,(MUS_CTL)
;	BIT	0,A
;	LD	A,BGMNO_FADEOFF
;	CALL	NZ,SETMUSIC
;
;	LD	A,BGMNO_STOP
;	CALL	SETMUSIC
;	CALL	PROC_MUSIC
;	CALL	PROC_MUSIC
;
;	RET

;--------------------------------------
PROC_MUSIC:	EQU PMUSIC

;--------------------------------------
; GRADIUS2/F-1 SPIRITは
; 全演奏停止コマンドが見つからなかったので
; 自分でワークエリアと音源レジスタを初期化
INIT_MUSIC_WORK:
	DI

	;RESET SOUND REGISTER
	LD	A,$FF
	LD	HL,SCCRFLG	;SCC REGISTER WRITE MASK
	LD	(HL),A
	INC	HL
	LD	(HL),A
	INC	HL		;SCC REG WORK
	LD	DE,SCCRWORK+1	;SCC REG WORK + 1
	LD	(HL),0		;TONE
	LD	BC,9
	LDIR
	INC	HL
	INC	DE
	LD	(HL),0		;VOL
	LD	BC,4
	LDIR
	INC	HL
	LD	(HL),0		;CH ENABLE

	CALL	SEL_SCC
	LD	HL,SCCRWORK	;SCC REG WORK
	LD	DE,SCCR_TONE1	;$9880	
	LD	BC,$10
	LDIR
	XOR	A
	LD	(SCCR_MODE),A	;$98C0
	CALL	RET_SCC

	;RESET PSG
	LD	A,0BFH
	LD	(PGSW_MIX),A
	LD	E,A
	LD	A,07H
	CALL	WRTPSG

	DI

	XOR	A
	LD	HL,MUS_CTL
	LD	(HL),A	;MUS_CTL
	INC	HL
	LD	(HL),A	;MUS_NO

	;RESET CHANNEL WORK
	LD	HL,CH_WORK1
	LD	DE,CH_WORK1+1
	LD	BC,$18F	;($28 * (8 + 2))
	LD	(HL),0
	LDIR

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
	LD	A,BGM_NO_MIN
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
	LD	A,BGM_NO_MAX
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
	INCLUDE	"GRA2TITL.ASM"
