;*********************************
;     TIMER & KEY  INTERRUPT
; RAM C000-FEFF > VRAM 8000-BEFF
;*********************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;       NAME  F1SP-EXP

PSG_SV:	EQU	VCBC+19	;0FB8BH+19
SCCWAV:	EQU	VCBA	;0FB41H

V_PG1:	EQU	2	;2*4000H= 8000H	;VRAM bit14-16
V_PG2:	EQU	4	;4*4000H=10000H	;VRAM bit14-16
V_PG3:	EQU	6	;6*4000H=18000H	;VRAM bit14-16
M_ADR:	EQU	0E000H
M_SIZE:	EQU	1CH	;E000H - FC00H

;VSYNC_MUTEX:	EQU	0E1C5H	;フレーム処理フラグ

;--------------------------------------
; WORK AREA
;--------------------------------------
SVW_SP:	EQU	SAVSP	; STACK SAVE AREA
;STACK:	EQU	BLDCHK+1	;DISK WORK AREA HEAD

;STACKA:	DW	M_ADR-2	; MY STACK ADDRESS
STACKA:	DW	0D300H-2	; MY STACK ADDRESS

CAPSTA:	DW	0
W_CAP:	DB	0

;--------------------------------------
EX_TRAP:
	DI
;	IM	0

;	LD	HL,VSYNC_MUTEX	;フレーム処理ブロック時はスキップ（転送中などの画像化け対策）
;	BIT	0,(HL)
;	JP	NZ,TRAP_MS

	; WAIT UNTIL RELEASE KEY
	IN	A,(KEYIO1)
	AND	0F0H
	OR	7
	OUT	(KEYIO1),A
	IN	A,(KEYIO0)
;	AND	4	;ESC
	AND	10H	;STOP
	JP	NZ,TRAP_MS

;	LD	A,(CURE_FLAG)
;	OR	A
;	CALL	NZ,CURE_TRAP

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

	; SAVE SCC
	LD	A,3FH
	LD	(BANK2),A
	LD	HL,SCCR_WAVE1	;9800H
	LD	DE,SCCWAV
	LD	BC,80H
	LDIR

	XOR	A
	LD	(SCCR_CHENA),A

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
	JR	NZ,J_CAP
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

	; RESTORE SCC BANK
	LD	A,3FH
	LD	(BANK2),A
	LD	HL,SCCWAV
	LD	DE,9800H
	LD	BC,80H
	LDIR

;	LD	A,(SCCMXW)
;	LD	(SCCR_CHENA),A
	LD	HL,SCCRWORK
	LD	DE,SCCR_TONE1	;9880H
	LD	BC,10H
	LDIR

	LD	A,(WBANK2)
	LD	(BANK2),A

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
;	DW	0420H,PLAY_	;'P'
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

	JP	RUN_ADR

;--------------------------------------
; F1SPIRIT TRAINNER

CURE:	;なんもなし
	LD	A,255
	LD	(0E310H),A	;FUEL 1P
	LD	(0E3D0H),A	;FUEL 2P
	XOR	A
	LD	(0E328H),A	;NO DAMAGE 1P
	LD	(0E3E8H),A	;NO DAMAGE 2P

	LD	A,1
	LD	(0E331H),A	;1位 1P
	LD	(0E3F1H),A	;1位 2P
	;LD	(CURE_TRAP),A	;常に1位

	LD	A,2
	LD	(0E1DEH),A	;Q-BERT/KING KONG2 (ENABLE ALL COURSE)

	LD	A,1
	LD	(0E1FDH),A	;ESCON    F5でリタイアできるようになる
	LD	(0E1D6H),A	;HYPEROFF ピットインが素早くなる
	LD	(0E1DFH),A	;MAXPOINT ポイントがMAXになる
;	JP	L_FUNC
	JP	RETURN

;CURE_TRAP:
;	PUSH	AF
;	LD	A,1
;	LD	(0E331H),A	;1位 1P
;	LD	(0E3F1H),A	;1位 2P
;	POP	AF
;	RET
;CURE_FLAG:
;	DB	0

;openMSX/share/script/_trainerdefs.tcl
;create_trainer "F1 Spirit - The Way To Formula 1" {time 1} {
;	"All Combis With Konami Carts" {dpoke 0xe1de 2}
;	"Escon" {dpoke 0xe1fd 1} ;#F5でリタイアできるようになる。
;	"Hyperoff" {dpoke 0xe1d6 1} ;#ピットインが素早くなる。
;	"Maxpoint" {dpoke 0xe1df 1} ;#ポイントがMAXになる。
;	"Player 1 Always First Place" {dpoke 0xe331 1}
;	"Player 1 Fuel" {dpoke 0xe310 255}
;	"Player 1 No Damage (bitmask)" {dpoke 0xe328 0}
;	"Player 2 Damage" {dpoke 0xe3e8 0}
;	"Player 2 Fuel" {dpoke 0xe3d0 255}
;	"Player 2 Position" {dpoke 0xe3f1 1}
;}

