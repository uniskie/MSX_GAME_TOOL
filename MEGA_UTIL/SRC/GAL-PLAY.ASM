;***************************************
;  in-game JUKEBOX for Maze of GALIOUS
;***************************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
; GALIOUS ROM RUTINES
;--------------------------------------
SETMUSIC:	EQU	4E34H
PMUSIC:	EQU	6004H

MUS_NO:	EQU	0E1C7H

; GALIOUS FONT
SELFONTBANK:	EQU	41D0H
SETFONT0:	EQU	5C46H
SETFONT1:	EQU	5AB3H

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
WAITCT:	DB	0	;WAIT CNT

;--------------------------------------
; ROUTINES
;--------------------------------------

;--------------------------------------
;PLAY_TRAP:	EQU	PLAY_TRAP

;--------------------------------------
PLAY_END:
	DI
	; MUTE PSG
	LD	BC,300H + PSGIOA
	LD	A,0BFH
	LD	E,7
	OUT	(C),E		;R#7: MIX
	OUT	(PSGIOW),A	;0BFH - MUTE ALL
	XOR	A
PLAY_END_PL:
	INC	E
	OUT	(C),E		;R#8-10: VOL
	OUT	(PSGIOW),A	;0
	DJNZ	PLAY_END_PL

	JP	PLAY_R

;--------------------------------------
PLAY_TR:
	CALL	RDVDP
	CALL	PMUSIC
#IF exists PLAY_TR_DISP
	CALL	PLAY_TR_DISP
#ENDIF
	LD	A,(WAITCT)
	ADD	A,1
	SBC	A,0	; 255 = STOP
	LD	(WAITCT),A
	RET

;--------------------------------------
PLAY_SUB:
	DI

	LD	A,2	;CURSOR:EXIT
	LD	(PLAYWK+2),A

	LD	A,(MUS_NO)	;CURRENT BGM
	LD	(PLAYWK+0),A

	XOR	A	;STOP BGM
	CALL	SETMUSIC

	LD	A,(PLAYWK+0)
	CALL	SETMUSIC

	CALL	DRAW_PLAY_INIT

;--------------------------------------
L_PLAY:
#IF exists DRAW_PLAY_LOOP
	CALL	DRAW_PLAY_LOOP
#ENDIF
	XOR	A
	LD	(WAITCT),A
	EI
L_PLAYW:
;#IF exists USE_KEYBUFFER
;	CALL	KEYUPD	;KEY MATRIX UPDATE
;#ENDIF
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
;#IF exists USE_KEYBUFFER
;	CALL	KEYTRG	;D=KEYMTX NO / E=MASK
;#ELSE
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
;#ENDIF
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

;#IF exists USE_KEYBUFFER
;	CALL	KEYUPD	;KEY MATRIX UPDATE
;#ENDIF
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
	JR	P_RIGH.@1
;--------------------------------------
P_RIGH:	LD	C,1
.@1:	CALL	P_LCH
	OR	A
	JR	NZ,P_ADD2
P_ADD:	LD	A,(HL)
	ADD	A,C
	CP	31H
	JR	C,P_NUM1
	SUB	30H
	JR	P_NUM1
P_ADD2:	LD	A,(HL)
	ADD	A,C
;	AND	127
	OR	128
	CP	96H
	JR	C,P_NUM2
	CP	FBH
	JR	NC,P_NUM2
	ADD	A,FBH-96H
P_NUM2:	LD	(HL),A
#IF exists DRAW_UPD_NUM2
	CALL	DRAW_UPD_NUM2
#ENDIF
	JP	L_PLAY

;--------------------------------------
P_DEL:	LD	C,4
	JR	P_LEFT.@1
;--------------------------------------
P_LEFT:	LD	C,1
.@1:	CALL	P_LCH
	OR	A
	JR	NZ,P_SUB2
P_SUB:	LD	A,(HL)
	SUB	C
	JR	Z,.@1
	CP	31H
	JR	C,P_NUM1
.@1:	ADD	A,30H
P_NUM1:	LD	(HL),A

#IF exists DRAW_UPD_NUM1
	CALL	DRAW_UPD_NUM1
#ENDIF
	JP	L_PLAY
P_SUB2:	LD	A,(HL)
	SUB	C
;	AND	127
	OR	128
	CP	96H
	JR	C,P_NUM2
	CP	FBH
	JR	NC,P_NUM2
	SUB	FBH-96H
	JR	P_NUM2

;--------------------------------------
P_DOWN:	LD	A,(PLAYWK+2)
	DEC	A
	CP	255
	JR	NZ,L_PUD
	LD	A,2
	JP	L_PUD

;--------------------------------------
P_UP:	LD	A,(PLAYWK+2)
	INC	A
	CP	3
	JR	NZ,L_PUD
	XOR	A
L_PUD:	LD	(PLAYWK+2),A
#IF exists DRAW_UPD_CUR
	CALL	DRAW_UPD_CUR
#ENDIF
	JP	L_PLAY

;--------------------------------------
P_HOME:	XOR	A
	LD	(0E1C1H),A
	INC	A
	LD	(0E1C0H),A
	JP	L_PLAY

;--------------------------------------
P_STOP:
	XOR	A
	CALL	SETMUSIC
	JP	L_PLAY

;--------------------------------------
P_SPAC:	LD	A,(PLAYWK+2)
	CP	2
	JP	Z,PLAY_END
	CALL	P_LCH
	LD	C,(HL)
	JR	Z,J_PL3
	LD	A,C
	CP	0FBH
	JR	NC,J_PL3
	XOR	A
	CALL	SETMUSIC
J_PL3:	LD	A,C
	CALL	SETMUSIC
.@1:	LD	DE,0801H
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JR	Z,.@1	; ≈Ωœ√ﬁœ¬
	JP	L_PLAY


