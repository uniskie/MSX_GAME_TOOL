;****** GRADIUS2 MUSIC TITLES ******

;GET TITLE
; IN:	A=BGM NO.
; OUT:	HL=STRING ADDRESS
; USE:	AF,DE,HL
GET_TTL:
	LD	DE,14
	LD	HL,MUS_TIT
GET_TTL_L:
	BIT	7,(HL)
	JR	NZ,GET_TTL_D
	CP	(HL)
	JR	Z,GET_TTL_D
	ADD	HL,DE
	JR	GET_TTL_L
GET_TTL_D:	;DETECT
	INC	HL
	RET

; MUSIC DATA ADDRESS TABLE (6612H + MUS_NO * 2)
;      669A, 66A0, 66A6, 66AC, 66B2, 66B8, 66BE, 01H-07H
;66C4, 66CA, 66D0, 66D6, 66DC, 66E2, 66E8, 66EE, 08H-0FH
;66F4, 66FA, 6700, 6706, 670C, 6712, 6718, 671E, 10H-17H
;6724, 672A, 6730, 6736, 673C, 6742, 6748, 674E, 18H-1FH
;6754, 675A, 6760, 6766, 676C, 6772, 6778, 677E, 20H-27H
;6784, 678A, 6798, 67A6, 67B4, 67C2, 67D0, 67DE, 28H-2FH
;67EC, 67FA, 6808, 6816, 6824, 6832, 6840, 684E, 30H-37H
;6860, 6872, 6884, 6896, 68A8, 68BA, 68CC, 68DE, 38H-3FH
;68F0, 68FE, 6910, 6922,                         40H-43H

MUS_TIT:
	DB $3F, '  OPENING   ‘'	; f		Above the horizon
	DB $3E, '   START    ‘'	; X^[g	Starting point
	DB $2B, 'SPACE BATTLE‘'	; σν	A journey to the start
	DB $2C, '  STAGE 1   ‘'	; 1Κ		Killer coast land
	DB $2D, '  STAGE 2   ‘'	; 2Κ		A planet of plants
	DB $2E, '  STAGE 3   ‘'	; 3Κ		Red diamond
	DB $31, '  STAGE 4   ‘'	; 4Κ		Dancing Venus
	DB $30, '  STAGE 5   ‘'	; 5Κ		Blazed up
	DB $32, '  STAGE 6   ‘'	; 6Κ		Frontier disputes
	DB $33, '  STAGE 7   ‘'	; 7Κ		Don't leave me alone
	DB $36, 'EXTRA STAGE ‘'	; B΅Κ	Tears began gushing
	DB $29, 'FINAL STAGE ‘'	; 14Κ		Moonspin
	DB $34, '    BOSS    ‘'	; {X		A fighter
	DB $35, '   INSIDE   ‘'	; RAΰ	Powerful waves
	DB $40, '   RETURN   ‘'	; Τf	Killer love
	DB $41, '   ENDING   ‘'	; GfBO	A dream of dreamer
	DB $42, '  GAMEOVER  ‘'	; Q[I[o[The war is over
	DB $80, '  --------  ‘'	; 

TITLE_STR:
	DW	3800H
#IF exists _AILZ80ASM_
	charmap @MSX, "MSX_chara.json"
	DB	@MSX:'‘@fq`chtrQ@Fitjd|anw@’'
	DB	@MSX:' @@@@@@@@@@@@@@@@@@@@@@@@@@@@@@ '
	DB	@MSX:' @rntmc@OO@@@@@@@@@@@@@@@@@@@@@ '
	DB	@MSX:' @@@@@@@@@@@‘’ '
	DB	@MSX:' @ltrhb@OO@@ @@@@@@@@@@@@@@@@@  '
	DB	@MSX:' @@@@@@@@@@@€£ '
	DB	@MSX:' @dwhs@@@@@@@@@irsnojFrsno|afl@ '
	DB	@MSX:'€ignldjFe`cd|nts@£'
	DB	@MSX:'‘'
#ELSE
	DB	'XWW GRADIUS2 :JUKE-BOX WWWWWWWWY'
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
TTL_BGM_X:	EQU	16
TTL_BGM_Y:	EQU	4
TTL_BGM_W:	EQU	17
