;*********************************
;     TIMER & KEY  INTERRUPT
; RAM C000-FEFF > VRAM 8000-BEFF
;*********************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;       NAME  GAL-EXPS

PSG_SV:	EQU	VCBC+19	;0FB8BH+19

V_PG1:	EQU	2	;2*4000H= 8000H	;VRAM bit14-16
V_PG2:	EQU	4	;4*4000H=10000H	;VRAM bit14-16
V_PG3:	EQU	6	;6*4000H=18000H	;VRAM bit14-16
M_ADR:	EQU	0E000H
M_SIZE:	EQU	1CH	;E000H - FC00H


;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
SVW_SP:	EQU	SAVSP	; STACK SAVE AREA
;STACK:	EQU	BLDCHK+1	;DISK WORK AREA HEAD

;STACKA:	DW	M_ADR-2	; MY STACK ADDRESS
STACKA:	DW	0D300H-2	; MY STACK ADDRESS

CAPSTA:	DW	0
W_CAP:	DB	0

;--------------------------------------
;--------------------------------------
;--------------------------------------
EX_TRAP:
	DI
;	IM	0

	; WAIT UNTIL RELEASE KEY
	IN	A,(KEYIO1)
	AND	0F0H
	OR	7
	OUT	(KEYIO1),A
	IN	A,(KEYIO0)
;	AND	4	;ESC
	AND	10H	;STOP
	JP	NZ,TRAP_MS

	;--------------------------------------
	LD	(SVW_SP),SP
	LD	HL,(STACKA)
	LD	SP,HL

	; SAVE PSG REG.
	LD	HL,PSG_SV
	LD	BC,PSGIOR
	XOR	A
L_PSGSV:
	OUT	(PSGIOA),A
	INI
	INC	A
	CP	13
	JP	NZ,L_PSGSV

	;(SAFETY ACCESS PSG R#7 JOYSTICK I/O)
	LD	A,(PSG_SV+7)
	AND	3FH
	OR	80H
	LD	(PSG_SV+7),A	; 10XXXXXX

	; MUTE PSG
	CALL	MUTE_PSG

	XOR	A
	CALL	CHGCAP

;--------------------------------------
;	LD	DE,0704H	;ESC
	LD	DE,0710H	;STOP
L_MENU_START_WAIT:
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,L_MENU_START_WAIT
S_CAP:	LD	DE,0
L_FUNC:	LD	HL,FC_TBL
L_FUNC_:
;MSX1未対応なのでvsync監視待ちはしない
;	CALL	WTVSYNC
;	CP	1
;	JR	NZ,J_CAP_
;	INC	DE
;	LD	A,E
;	AND	32	;32 FRAME

	INC	DE
	LD	A,D
	AND	20H	;2000H

;--------------------------------------
	LD	A,1
	JP	NZ,J_CAP
	XOR	A
J_CAP:	LD	BC,(CAPSTA)
	CP	C
	LD	(CAPSTA),A
	CALL	NZ,CHGCAP
J_CAP_:
	PUSH	DE
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	LD	A,E
	OR	D
	EX	AF,AF'	;AF':DE=0 ->LOOP
	INC	HL
	LD	C,(HL)
	INC	HL
	LD	B,(HL)
	INC	HL
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	POP	DE
	JP	NZ,L_FUNC_
	EX	AF,AF'	;AF:DE=0 ->LOOP
	LD	A,0
	CALL	NZ,CHGCAP
	LD	H,B
	LD	L,C
	JP	(HL)

;--------------------------------------
RETURN_AT:
	JP	S_CAP

;--------------------------------------
RETURN:
;	LD	DE,0704H	;ESC
	LD	DE,0710H	;STOP
L_RET:	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,L_RET

	; RESTORE PSG
	LD	HL,PSG_SV
	LD	BC,PSGIOW
	XOR	A
L_PSGLD:
	OUT	(PSGIOA),A
	OUTI
	INC	A
	CP	13
	JP	NZ,L_PSGLD

	LD	A,1
	CALL	CHGCAP
	LD	SP,(SVW_SP)
;	IM	1
	JP	TRAP_MS

;--------------------------------------
; FUNCTIONS: [KEY]
FC_TBL:	DW	0602H,CTRL	; CTRL
	DW	0501H,SAVE	;'S'
	DW	0402H,LOAD	;'L'
	DW	0301H,CURE	;'C'
	DW	0420H,PLAY	;'P'
;	DW	0704H,RETURN	; ESC
	DW	0710H,RETURN	; STOP
	DW	0,L_FUNC	; END of DATA

;--------------------------------------
; FUNCTIONS: [CTRL]+[KEY]
CTRL:	LD	HL,FC_TBL_AT
	JP	L_FUNC_
FC_TBL_AT:
	DW	0120H,QUIT	;'@'
	DW	0501H,SAVE_AT_Q	;'S'
	DW	0402H,LOAD_AT	;'L'
	DW	0420H,PLAY	;'P'
	DW	0710H,RESET	; STOP
	DW	0,L_FUNC	; END of DATA

;--------------------------------------
SAVE_AT_Q:
	LD	A,V_PG2
	CALL	SAVE_
QUIT:
	LD	A,255
	LD	(SAV_REF),A
	LD	A,V_PG1
	CALL	SAVE_
	LD	A,V_PG3
	CALL	LOAD_
	JP	RET_BAS	;COMMON


;--------------------------------------
SAVE_AT:
	LD	A,255
	LD	(SAV_REF),A
	LD	A,V_PG1
	JP	SAVE_P
SAVE:	LD	A,V_PG2
SAVE_P:	LD	HL,RETURN_AT
	PUSH	HL
SAVE_:	INC	A
	LD	(SAVE__+1),A
	DEC	A
	LD	HL,M_ADR
	LD	B,M_SIZE
	LD	C,20H+40H
	CALL	TF_VRM

	LD	D,0
L_SAVE:	LD	C,D
	LD	HL,BUF
	LD	B,1
	LD	A,0
	CALL	TF_RAM
	LD	A,40H
	OR	D
	LD	C,A
	LD	HL,BUF
	LD	B,1
SAVE__:	LD	A,0	;vram page +1
	CALL	TF_VRM
	CALL	VRESET

	INC	D
	LD	A,40H
	SUB	D
	JP	NZ,L_SAVE

	RET

;--------------------------------------
LOAD_AT:
	LD	A,V_PG1
	JP	LOAD_M
LOAD:	LD	A,V_PG2
LOAD_M:
	LD	HL,(STACKA)
	LD	SP,HL
	LD	HL,RETURN_AT
	PUSH	HL
LOAD_:	LD	D,0
	LD	(LOAD__+1),A
	INC	A
	LD	(L_LOAD+1),A
L_LOAD:	LD	A,0	;vram page +1
	LD	HL,BUF
	LD	B,1
	LD	C,D
	CALL	TF_RAM
	LD	A,40H
	OR	D
	LD	C,A
	LD	HL,BUF
	LD	B,1
	LD	A,0
	CALL	TF_VRM

	INC	D
	LD	A,40H
	SUB	D
	JP	NZ,L_LOAD

	LD	HL,M_ADR
	LD	B,M_SIZE
	LD	C,20H
LOAD__:	LD	A,0	;vram page
	CALL	TF_RAM
	CALL	VRESET

;	LD	A,(WBANK0)
;	LD	(BANK0),A
	LD	A,(WBANK1)
	LD	(BANK1),A
	LD	A,(WBANK2)
	LD	(BANK2),A
	LD	A,(WBANK3)
	LD	(BANK3),A
	CALL	WR_CRG
	RET

;--------------------------------------
RESET:	
	LD	DE, 0602H	; CTRL
RESET1:	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,RESET1
;	LD	DE,0704H	;ESC
	LD	DE,0710H	;STOP
RESET2:	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,RESET2

	LD	SP,GAMESPA

	LD	A,1
	CALL	CHGCAP

	JP	40ABH

;--------------------------------------
; GALIOUS TRAINER

CURE:
	;POPOLON
	LD	A,(LIFE1W)
	OR	A	;CHECK ZERO
	LD	B,A
	JR	NZ,CURENR1
	LD	A,1
	LD	(PL_REST2),A	;REVIVE POPOLON
CURENR1:
	LD	A,(LIFE1W+1)
	SUB	B
	LD	(LIFEUP1),A

	;APHRODITE
	LD	A,(LIFE2W)
	OR	A	;CHECK ZERO
	LD	B,A
	JR	NZ,CURENR2
	LD	A,1
	LD	(PL_REST1),A	;REVIVE APHRODITE
CURENR2:
	LD	A,(LIFE2W+1)
	SUB	B
	LD	(LIFEUP2),A

	LD	HL,ITEM_W
	LD	DE,999H
	LD	B,3
L_CURE:	LD	(HL),E
	INC	HL
	LD	(HL),D
	INC	HL
	DJNZ	L_CURE
	JP	RETURN

PLAYERNO:	EQU	0E04DH	;0:POPOLON / 1:APHRODITE
PL_REST1:	EQU	0E058H	;ENABLE POPOLON ->  APHRODITE
				;APHRODITE死亡時のみ書き換えが望ましい
				;それ以外はバグる
PL_REST2:	EQU	0E059H	;ENABLE APHRODITE -> POPOLON
				;POPOLON死亡時のみ書き換えが望ましい
				;それ以外はバグる

EXP1W:	EQU	0E054H	;CUR/MAX (SIGNED 8BIT)
EXP2W:	EQU	0E050H	;CUR/MAX (SIGNED 8BIT)
LIFE1W:	EQU	0E056H	;CUR/MAX (SIGNED 8BIT)
LIFE2W:	EQU	0E052H	;CUR/MAX (SIGNED 8BIT)

EXPUP1:	EQU	0E060H	;(SIGNED 8BIT)
EXPUP2:	EQU	0E05DH	;(SIGNED 8BIT)
LIFEUP1:	EQU	0E061H	;(SIGNED 8BIT)
LIFEUP2:	EQU	0E05EH	;(SIGNED 8BIT)

ITEM_W:	EQU	0E046H

WR_AROW:	EQU	05F79H
WR_COIN:	EQU	05F84H
WR_KEYS:	EQU	05F8FH
WR_LIF1:	EQU	0618BH
WR_LIF2:	EQU	061B2H

;;--------------------------------------
;; CALL MUSIC PLAYER
;PLAY_:	LD	HL,0C007H
;	BIT	7,(HL)
;	JP	Z,J_PLAY_
;	XOR	A
;	CALL	4E34H
;J_PLAY_:	LD	A,(HL)
;	CALL	4E34H
;	DI
;	JP	RETURN

