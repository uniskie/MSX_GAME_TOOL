;GET TITLE
; IN:	A=BGM NO.
; OUT:	HL=STRING ADDRESS
; USE:	AF,B,HL
GET_TTL:
	LD	HL,MUS_TIT
GET_TTL_L:
	BIT	7,(HL)
	JR	NZ,GET_TTL_N
	CP	(HL)
	INC	HL
	JR	Z,GET_TTL_D
	INC	HL
	INC	HL
	JR	GET_TTL_L
GET_TTL_N:	;NONE
	LD	HL,MUSTN
	RET
GET_TTL_D:	;DETECT
	LD	A,(HL)
	LD	B,A
	INC	HL
	LD	A,(HL)
	LD	H,A
	LD	L,B
	RET

;****** F1SPIRIT MUSIC TITLES  ******

MUS_TIT: 
#IF exists _AILZ80ASM_
	DB	33H, low MUST0, high MUST0
	DB	34H, low MUST1, high MUST1
	DB	35H, low MUST2, high MUST2
	DB	36H, low MUST3, high MUST3
	DB	37H, low MUST6, high MUST6
	DB	38H, low MUST9, high MUST9
	DB	39H, low MUST3, high MUST3 ;*DUP
	DB	3AH, low MUST6, high MUST6 ;*DUP
	DB	3BH, low MUST9, high MUST9 ;*DUP
	DB	3CH, low MUSTA, high MUSTA
;	DB	3DH, low MUSTA, high MUSTA ;*NONE*
	DB	3EH, low MUST8, high MUST8
	DB	3FH, low MUST5, high MUST5
	DB	40H, low MUSTB, high MUSTB
	DB	41H, low MUST4, high MUST4
	DB	42H, low MUST4, high MUST4 ;*DUP
	DB	43H, low MUST7, high MUST7
	DB	80H
#ELSE
	DB	33H, MUST0 AND 0FFH, MUST0 / 100H
	DB	34H, MUST1 AND 0FFH, MUST1 / 100H
	DB	35H, MUST2 AND 0FFH, MUST2 / 100H
	DB	36H, MUST3 AND 0FFH, MUST3 / 100H
	DB	37H, MUST6 AND 0FFH, MUST6 / 100H
	DB	38H, MUST9 AND 0FFH, MUST9 / 100H
	DB	39H, MUST3 AND 0FFH, MUST3 / 100H ;*DUP
	DB	3AH, MUST6 AND 0FFH, MUST6 / 100H ;*DUP
	DB	3BH, MUST9 AND 0FFH, MUST9 / 100H ;*DUP
	DB	3CH, MUSTA AND 0FFH, MUSTA / 100H
;	DB	3DH, MUSTA AND 0FFH, MUSTA / 100H ;*NONE*
	DB	3EH, MUST8 AND 0FFH, MUST8 / 100H
	DB	3FH, MUST5 AND 0FFH, MUST5 / 100H
	DB	40H, MUSTB AND 0FFH, MUSTB / 100H
	DB	41H, MUST4 AND 0FFH, MUST4 / 100H
	DB	42H, MUST4 AND 0FFH, MUST4 / 100H ;*DUP
	DB	43H, MUST7 AND 0FFH, MUST7 / 100H
	DB	80H
#ENDIF

;		'                 ';17
MUST0:	DB	'   F-1 SHUFFLE   ｡';33H, (TITLE)
MUST1:	DB	'  STARTING GRID  ｡';34H, (START)
MUST2:	DB	'       D/G       ｡';35H, (SETTING)
MUST3:	DB	'HOT SUMMER RIDING｡';36H, (STOCK CAR & F-3)
MUST4:	DB	'RANDOM APPOROACH ｡';41H, (RALLY)
MUST5:	DB	'      NEXT       ｡';3FH, (RETIRE)
MUST6:	DB	' SELF-CONFIDENCE ｡';37H, (F-3000)
MUST7:	DB	' VANISHING HEAT  ｡';43H, (ENDURANCE)
MUST8:	DB	'   WINNING RUN   ｡';3EH, (GOAL)
MUST9:	DB	'    F-1 SPIRIT   ｡';38H, (F-1)
MUSTA:	DB	'     FAILED!     ｡';3CH, (PIT)
MUSTB:	DB	'STREET COLLECTION｡';40H, (ENDING)
MUSTN:	DB	'  -------------  ｡'

TITLE_STR:
#IF exists _AILZ80ASM_
	charmap @MSX, "MSX_chara.json"
	DW	3800H
	DB	@MSX:'┌──　Ｆ１－ＳＰＩＲＩＴ　：ＪＵＫＥ－ＢＯＸ　───────┐'
	DB	@MSX:'│　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　│'
	DB	@MSX:'│　ＳＯＵＮＤ　００　　　　　　　　　ＮＯＷ　ＰＬＡＹＩＮＧ　│'
	DB	@MSX:'│　　　　　　　　　　　┌─────────────────┐│'
	DB	@MSX:'│　ＭＵＳＩＣ　００　　│　　　　　　　　　　　　　　　　　││'
	DB	@MSX:'│　　　　　　　　　　　└─────────────────┘│'
	DB	@MSX:'│　ＥＸＩＴ　　　　　　　　　（ＳＴＯＰ）：ＳＴＯＰ－ＢＧＭ　│'
	DB	@MSX:'└──────────────（ＨＯＭＥ）：ＦＡＤＥ－ＯＵＴ　┘'
	DB	@MSX:'｡'
#ELSE
	DW	3800H
	DB	'XWW F1-SPIRIT :JUKE-BOX WWWWWWWY'
	DB	'V                              V'
	DB	'V SOUND 00         NOW PLAYING V'
	DB	'V           XWWWWWWWWWWWWWWWWWYV'
	DB	'V MUSIC 00  V                 VV'
	DB	'V           ZWWWWWWWWWWWWWWWWW[V'
	DB	'V EXIT         (STOP):STOP-BGM V'
	DB	'ZWWWWWWWWWWWWWW(HOME):FADE-OUT ['
	DB	'｡'
#ENDIF