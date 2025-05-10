;*********************************
;     TIMER & KEY  INTERRUPT
; RAM C000-FEFF > VRAM 8000-BEFF
;*********************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;       NAME  GRA2-EXP

PSG_SV:	EQU	VCBC+19	;0FB8BH+19
SCCWAV:	EQU	VCBA	;0FB41H

;--------------------------------------
;GAME:
;	VRAM: 16KByte
;	RAM : 8KByte ($e000-$fc00)
;--------------------------------------
;VRAM SAVE Version:(Current Version)
; * MSX1: not work
; * RAM: 8KB
; * VRAM SAVE: easy in BASIC
; * Save Slot: 2
;
;$0000	(GAME)                    4KBytes
;$4000	(EMPTY)                   4KBytes
;$8000	AUTO SAVE  RAM  E000-FFFF 8KBytes
;	AUTO SAVE  VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;$10000	STATE SAVE RAM  E000-FFFF 8KBytes
;	STATE SAVE VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;$18000	BASIC      RAM  E000-FFFF 8KBytes
;	BASIC      VRAM 0000-3FFF 16KBytes
;	(EMPTY)                   8KBytes
;--------------------------------------

V_PG1:	EQU	2	;2*4000H= 8000H	;VRAM bit14-16
V_PG2:	EQU	4	;4*4000H=10000H	;VRAM bit14-16
V_PG3:	EQU	6	;6*4000H=18000H	;VRAM bit14-16
M_ADR:	EQU	0E000H
M_SIZE:	EQU	1CH	;E000H - FC00H

VSYNC_MUTEX:	EQU	0E1C5H	;フレーム落ちカウンタ

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

	LD	A,(VSYNC_MUTEX)	;フレーム落ち時はスキップ（転送中などの画像化け対策）
	AND	A
	JP	NZ,TRAP_MS

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

	;LD	A,(SCCMXW)
	;LD	(SCCR_CHENA),A
	LD	HL,SCCRWORK
	LD	DE,SCCR_TONE1	;9880H
	LD	BC,10H
	LDIR

	LD	A,(WBANK1)
	LD	(BANK1),A
	LD	A,(WBANK2)
	LD	(BANK2),A
	LD	A,(WBANK3)
	LD	(BANK3),A

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
; GRADIUS2 TRAINER

CURE:
	LD	IX,GAUGE_WORK

	;チートメニュー有効化（PRE RELEASEのみ）
	LD	HL,CHEAT_FLG
	LD	(HL),1

	;カートリッジ同時挿し解放
	LD	HL,CART_FLG
	LD	(HL),CART_FLG_GALIOUS + CART_FLG_Q_BERT

	;45秒間無敵 "METALION"+Qバート
	LD	HL,METALION_FLG
	LD	(HL),1

	;SPEED
	LD	HL,SPEED_LEVEL
	LD	(HL),2
	LD	(IX+GAUGEOFS_SPEED),2	;SPEED GAUGE

	;MISSILE
	LD	HL,MISSILE_FLG
	LD	(HL),MISSILE_NAPALM
	LD	(IX+GAUGEOFS_MISSILE),255	;MISSILE GAUGE

;	LD	A,(EXTRA_STEP)
;	CP	6
;	JR	C,.NO_BACKNBEAM
;	INC	IX
;
;;	;BACK BEAM (TAIL-GUN)
;;	LD	HL,BACKBEAM_FLG
;;	LD	(HL),2	;弾の数 普通は2
;;	LD	(GAUGE_WORK+GAUGEOFS_BACKBEAM),255	;BACKBEAM GAUGE
;.NO_BACKNBEAM

	;DOUBLE
	LD	HL,DOUBLE_FLG
	LD	(HL),1	;弾の数 普通は2
;	LD	(IX+GAUGEOFS_DOUBLE),255	;DOUBLE GAUGE

;	;UPLASER
;	LD	HL,UPLASER_FLG
;	LD	(HL),2	;弾の数 普通は2

;	;DOWNLASER
;	LD	HL,DOWNLASER_FLG
;	LD	(HL),2	;弾の数 普通は2

	;LASER
	LD	HL,SHOT_FLG
	LD	(HL),0	;通常弾OFF
	LD	HL,LASER_FLG
	LD	(HL),LASER_NORMAL_LASER
	LD	(IX+GAUGEOFS_LASER),1; LASER GAUGE

	;OPTION
	LD	HL,OPTION_FLG
	LD	(HL),2	;オプションの数
	LD	HL,OPTION_SPR1
	LD	(HL),1	;SPRITE ON
	LD	HL,OPTION_SPR2
	LD	(HL),1	;SPRITE ON
	LD	(IX+GAUGEOFS_OPTION),255; OPTION GAUGE

	;SHILED
	LD	HL,SHIELD_FLG
	LD	(HL),2	;1=NONE / 2=SHIELD / 3=ROTARY DRILL
	LD	(IX+GAUGEOFS_SHIELD),255; SHIELD GAUGE

;	;EXTRA WEAPON
;	LD	HL,EXTRA_WEPON_FLG
;	LD	(HL),EXTRA_VECTOR_LASER

	;LIFE
	LD	HL,LIFE_CNT
	LD	(HL),99H

	JP	RETURN

CHEAT_FLG:		EQU	0F0F6H

CART_FLG:		EQU	0F0F5H
CART_FLG_Q_BERT:	EQU	1
CART_FLG_PENGUIN:	EQU	4
CART_FLG_GALIOUS:	EQU	8
CART_FLG_ALL:		EQU	255

EXTRA_STEP		EQU	0E20FH	;エクストラ武器の進行度：0から7まで
					; 0: NORMAL
					; 1: UP LASER
					; 2: DOWN LASER
					; 3: NAPALM
					; 4: REFLEX RING
					; 5: EXTEND LASER
					; 6: BACKBEAM
					; 7: FIRE BLASTER

GAUGE_POS:		EQU	0E330H	;現在のカプセルゲージ位置 （未所持は0）
GAUGE_COUNT:		EQU	0E331H	;(ゲージの数+1) 7 - 10

GAUGE_WORK:		EQU	0E334H	;-0E33CH : 6個～9個
	;SPEED MISSILE [BACKBEAM] DOUBLE [UPLASER] [DOWNLASER] LASER OPTION SHIELD
GAUGEOFS_SPEED:		EQU	0	;MAX 7
GAUGEOFS_MISSILE:	EQU	1	;MAX 3
GAUGEOFS_DOUBLE:	EQU	2	;2=REFLEX RING/3(MAX)=FIRE BLASTER→レーザーだけどダブルゲージを使う
GAUGEOFS_LASER:		EQU	3	;3(MAX)=EXTEND LASER
GAUGEOFS_OPTION:	EQU	4
GAUGEOFS_SHIELD:	EQU	5
GAUGE_POS_DECIDED:	EQU	0E33DH	;パワーアップ実行時のカプセルゲージ位置

LIFE_CNT:		EQU	0E200H	;153

SHIELD_FLG:		EQU	0E400H	;2 = SHIELD / 3=ROTARY DRIL

SPEED_LEVEL:		EQU	0E402H

OPTION_FLG:		EQU	0E40BH
OPTION_SPR1:		EQU	0E410H
OPTION_SPR2:		EQU	0E420H

SHOT_FLG:		EQU	0E430H; 2 

DOUBLE_FLG:		EQU	0E431H; 2

LASER_FLG:		EQU	0E432H
LASER_NORMAL_LASER:	EQU	1
LASER_DOUBLE_LASER:	EQU	2
LASER_EXTEND_LASER:	EQU	3
LASER_REFLEX_RING:	EQU	5
LASER_FIRE_BLASTER:	EQU	6

MISSILE_FLG:		EQU	0E433H
MISSILE_NORMAL:		EQU	1
MISSILE_DOUBLE:		EQU	2
MISSILE_NAPALM:		EQU	3

UPLASER_FLG:		EQU	0E434H	;MAX 2
DOWNLASER_FLG:		EQU	0E435H	;MAX 2
BACKBEAM_FLG:		EQU	0E436H	;0 or 2

EXTRA_WEPON_FLG:	EQU	0E439H
EXTRA_ROLLING_OPTION:	EQU	3
EXTRA_ROTARY_DRILL:	EQU	4	;これだけでは無効→SHIELD_FLGを3に設定する
EXTRA_ENEMY_SLOW:	EQU	5
EXTRA_VECTOR_LASER:	EQU	7

METALION_FLG:		EQU	0E446H

;create_trainer "Gradius 2 - Nemesis 2" {time 0.5} {
;	"Activate Cheat Menu (pre Release Only)" {dpoke 0xf0f6 1}
;	"All Konami Cart Combinations Activated" {dpoke 0xf0f5 255}
;	"Combi: Penguin Adventure Mode" {dpoke 0xf0f5 4}
;	"Combi: Q-bert Mode" {dpoke 0xf0f5 1}
;	"Combi: The Maze Of Galious Mode" {dpoke 0xf0f5 8}
;	"Metalion Mode" {dpoke 0xe446 1}
;	"Nice Vic Viper Colors" {dpoke 0xe283 14;poke 0xe408 15}
;	"Stage: Bonus Stage 1" {dpoke 0xe201 9}
;	"Stage: Bonus Stage 2" {dpoke 0xe201 10}
;	"Stage: Bonus Stage 3" {dpoke 0xe201 11}
;	"Stage: Core Stage" {dpoke 0xe201 8}
;	"Stage: Final Stage" {dpoke 0xe201 0}
;	"Lives: Lives" {dpoke 0xe200 153}
;	"Stage: Stage: Stage 1" {dpoke 0xe201 1}
;	"Stage: Stage: Stage 2" {dpoke 0xe201 2}
;	"Stage: Stage: Stage 3" {dpoke 0xe201 3}
;	"Stage: Stage: Stage 4" {dpoke 0xe201 4}
;	"Stage: Stage: Stage 5" {dpoke 0xe201 5}
;	"Stage: Stage: Stage 6" {dpoke 0xe201 6}
;	"Stage: Stage: Stage 7" {dpoke 0xe201 7}
;	"Weapon: Weapon: Speed Set To 5" {dpoke 0xe402 5}
;	"Weapon: Weapon: Options" {dpoke 0xe40b 2;poke 0xe410 1;dpoke 0xe420 1}
;	"Weapon: Weapon: Deactivate Normal Shoot" {dpoke 0xe430 0}
;	"Weapon: Weapon: Double" {dpoke 0xe431 2}
;	"Weapon: Weapon: Normal Laser" {dpoke 0xe432 1}
;	"Weapon: Weapon: Double Laser" {dpoke 0xe432 2}
;	"Weapon: Weapon: Extended Laser" {dpoke 0xe432 3}
;	"Weapon: Weapon: Reflex Ring" {dpoke 0xe432 5}
;	"Weapon: Weapon: Fire Blaster" {dpoke 0xe432 6}
;	"Weapon: Weapon: Normal Missile" {dpoke 0xe433 1}
;	"Weapon: Weapon: Double Missile" {dpoke 0xe433 2}
;	"Weapon: Weapon: Napalm Missile" {dpoke 0xe433 3}
;	"Weapon: Weapon: Up Laser" {dpoke 0xe434 2}
;	"Weapon: Weapon: Down Laser" {dpoke 0xe435 2}
;	"Weapon: Weapon: Back Beam" {dpoke 0xe436 2}
;	"Weapon: Weapon: Option Ring" {dpoke 0xe439 3}
;	"Weapon: Weapon: Rotary Drill" {dpoke 0xe439 4}
;	"Enemy Slow" {dpoke 0xe439 5}
;	"Weapon: Weapon: Vector Laser" {dpoke 0xe439 7}
;	"Weapon: Weapon: Shield Off" {dpoke 0xe400 0}
;	"Weapon: Weapon: Shield On" {dpoke 0xe400 2}
;}
