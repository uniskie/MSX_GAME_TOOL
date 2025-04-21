;*********************************
;     TIMER & KEY  INTERRUPT
; RAM C000-FEFF > VRAM 8000-BEFF
;*********************************
;       NAME  F1SP-EXP

PSG_SV:	EQU	VCBC+19	;0FB8BH+19
SCCWAV:	EQU	VCBA	;0FB41H

V_PG1:	EQU	2
V_PG2:	EQU	4
V_PG3:	EQU	6
M_SIZE:	EQU	1CH
M_ADR:	EQU	0E000H

SVW_SP:	EQU	SAVSP	; STACK SAVE AREA
;STACK:	EQU	BLDCHK+1	;DISK WORK AREA HEAD

SCCMXW:	EQU	0E1F3H	;Œˆ‚ß‘Å‚¿F‰¼

;--------------------------------------
; WORK AREA
;--------------------------------------
;STACKA:	DW	M_ADR-2	; MY STACK ADDRESS
STACKA:	DW	0D300H-2	; MY STACK ADDRESS

CAPSTA:	DW	0
W_CAP:	DB	0

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
	LD	A,7
	OUT	(PSGIOA),A
	LD	A,0BFH
	OUT	(PSGIOW),A

	; SAVE SCC
	LD	A,3FH
	LD	(BANK2),A
	LD	HL,9800H
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
;MSX1–¢‘Î‰ž‚È‚Ì‚ÅvsyncŠÄŽ‹‘Ò‚¿‚Í‚µ‚È‚¢
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
	LD	A,(SCCMXW)
	LD	(SCCR_CHENA),A
	LD	A,(W_BANK+1)
	LD	(BANK2),A

	CALL	CHGCAP
	LD	SP,(SVW_SP)
;	IM	1
	JP	TRAP_MS

;--------------------------------------
; FUNCTIONS: [KEY]
FC_TBL:	DW	0602H,CTRL	; CTRL
	DW	0501H,SAVE	;'S'
	DW	0402H,LOAD	;'L'
;	DW	0301H,CURE	;'C'
;	DW	0420H,PLAY	;'P'
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
	LD	(SSAV_REF),A
	LD	A,V_PG1
	CALL	SAVE_
	LD	A,V_PG3
	CALL	LOAD_
	JP	RET_BAS	;COMMON


;--------------------------------------
SAVE_AT:
	LD	A,255
	LD	(SSAV_REF),A
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

	INC	D
	LD	A,40H
	SUB	A,D
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
	SUB	A,D
	JP	NZ,L_LOAD

	LD	HL,M_ADR
	LD	B,M_SIZE
	LD	C,20H
LOAD__:	LD	A,0	;vram page
	CALL	TF_RAM

	LD	A,(W_BANK+0)
	LD	(BANK1),A
	LD	A,(W_BANK+1)
	LD	(BANK2),A
	LD	A,(W_BANK+2)
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

	LD	HL,(GAME_SP_ADR)
	LD	SP,HL

	LD	A,1
	CALL	CHGCAP

	LD	HL,(GAME_MAIN_ADR)
	JP	(HL)

;--------------------------------------
; F1SPIRIT TRAINNER

;CURE:	;‚È‚ñ‚à‚È‚µ
;	JP	L_FUNC

