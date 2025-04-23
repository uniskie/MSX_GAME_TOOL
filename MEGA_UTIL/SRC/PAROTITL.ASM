;******:	 PARODIUS  ******
;**:	MUSIC TITTLE DATAS **

MUS_TIT:
	DB	"  SE･N･TA･KU ! ｡"	;*DM*
	DB	"   OPENNING!   ｡"	;*DM*
	DB	"    ENDING..   ｡"	;*DM*
	DB	"   GAME OVER   ｡"	;*DM*
	DB	" SPACE  BATTLE ｡"	;*DM*
	DB	"     ENEMY     ｡"	;*DM*
	DB	"     BOSS !    ｡"	;*DM*
	DB	"  EXTRA STAGE  ｡"	;*DM*
	DB	"    STAGE: 1   ｡"	;*DM*
	DB	"    STAGE: 2   ｡"	;*DM*
	DB	"    STAGE: 3   ｡"	;*DM*
	DB	"    STAGE: 4   ｡"	;*DM*
	DB	"    STAGE: 5   ｡"	;*DM*
	DB	"    STAGE: 6   ｡"	;*DM*
	DB	"    --------   ｡"	;*DM*

TITLE_STR:
	DW	3800H
#IF exists _AILZ80ASM_
	charmap @MSX, "MSX_chara.json"
	DB	@MSX:"┌──　ＰＡＲＯＤＩＵＳ　：ＪＵＫＥ－ＢＯＸ　────────┐"	;*DM*
	DB	@MSX:"│　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　│"	;*DM*
	DB	@MSX:"│　ＳＯＵＮＤ　－００－　　　　　　　ＮＯＷ　ＰＬＡＹＩＮＧ　│"	;*DM*
	DB	@MSX:"│　　　　　　　　　　　　　┌───────────────┐│"	;*DM*
	DB	@MSX:"│　ＭＵＳＩＣ　－００－　　│　　　　　　　　　　　　　　　││"	;*DM*
	DB	@MSX:"│　　　　　　　　　　　　　└───────────────┘│"	;*DM*
	DB	@MSX:"│　ＥＸＩＴ　　　　　　　　　（ＳＴＯＰ）：ＳＴＯＰ－ＢＧＭ　│"	;*DM*
	DB	@MSX:"└──────────────（ＨＯＭＥ）：ＦＡＤＥ－ＯＵＴ　┘"	;*DM*
	DB	@MSX:"｡"
#ELSE
	DB	"XWW PARODIUS :JUKE-BOX WWWWWWWWY"	;*DM*
	DB	"V                              V"	;*DM*
	DB	"V SOUND -00-       NOW PLAYING V"	;*DM*
	DB	"V             XWWWWWWWWWWWWWWWYV"	;*DM*
	DB	"V MUSIC -00-  V               VV"	;*DM*
	DB	"V             ZWWWWWWWWWWWWWWW[V"	;*DM*
	DB	"V EXIT         (STOP):STOP-BGM V"	;*DM*
	DB	"ZWWWWWWWWWWWWWW(HOME):FADE-OUT ["	;*DM*
	DB	"｡"
#ENDIF