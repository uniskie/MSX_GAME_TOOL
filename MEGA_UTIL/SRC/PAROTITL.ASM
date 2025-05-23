;****** PARODIUS MUSIC TITLES ******

;GET TITLE
; IN:	A=BGM NO.
; OUT:	HL=STRING ADDRESS
; USE:	AF,B,HL
GET_TTL:
	LD	D,0
	LD	A,(PLAYWK)
	CP	30H
	JR	C,J_WTIT0
	CP	3EH
	JR	C,J_WTIT1

J_WTIT0:
	LD	A,3EH
J_WTIT1:
	SUB	30H
	RLA
	RLA
	RLA
	RLA
	JR	NC,J_WTIT3
	INC	D
J_WTIT3:
	AND	0F0H
	LD	E,A
	LD	HL,MUS_TIT
	ADD	HL,DE
	RET

MUS_TIT:
	DB	'  SE₯N₯TA₯KU ! ‘'
	DB	'    OPENING    ‘'
	DB	'    ENDING..   ‘'
	DB	'   GAME OVER   ‘'
	DB	' SPACE  BATTLE ‘'
	DB	'     ENEMY     ‘'
	DB	'     BOSS !    ‘'
	DB	'  EXTRA STAGE  ‘'
	DB	'    STAGE: 1   ‘'
	DB	'    STAGE: 2   ‘'
	DB	'    STAGE: 3   ‘'
	DB	'    STAGE: 4   ‘'
	DB	'    STAGE: 5   ‘'
	DB	'    STAGE: 6   ‘'
	DB	'    --------   ‘'

TITLE_STR:
	DW	3800H
#IF exists _AILZ80ASM_
	charmap @MSX, "MSX_chara.json"
	DB	@MSX:'‘@o`qnchtr@Fitjd|anw@’'
	DB	@MSX:' @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ '
	DB	@MSX:' @rntmc@OO@@@@@@@@@@@@@@@@@@@@@ '
	DB	@MSX:' @@@@@@@@@@@‘’ '
	DB	@MSX:' @ltrhb@OO@@ @@@@@@@@@@@@@@@@@  '
	DB	@MSX:' @@@@@@@@@@@€£ '
	DB	@MSX:' @dwhs@@@@@@@@@irsnojFrsno|afl@ '
	DB	@MSX:'€ignldjFe`cd|nts@£'
	DB	@MSX:'‘'
#ELSE
	DB	'XWW PARODIUS :JUKE-BOX WWWWWWWWY'
	DB	'V                              V'
	DB	'V SOUND 00                     V'
	DB	'V           XWWWWWWWWWWWWWWWWWYV'
	DB	'V MUSIC 00  V                 VV'
	DB	'V           ZWWWWWWWWWWWWWWWWW[V'
	DB	'V EXIT         (STOP):STOP-BGM V'
	DB	'ZWWWWWWWWWWWWWW(HOME):FADE-OUT ['
	DB	'‘'
#ENDIF

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
TTL_BGM_X:	EQU	14
TTL_BGM_Y:	EQU	4
TTL_BGM_W:	EQU	17

