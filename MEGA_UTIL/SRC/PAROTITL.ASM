;******:	 PARODIUS  ******
;**:	MUSIC TITTLE DATAS **

MUS_TIT:
	DB	"  SE･N･TA･KU ! ｡"
	DB	"   OPENNING!   ｡"
	DB	"    ENDING..   ｡"
	DB	"   GAME OVER   ｡"
	DB	" SPACE  BATTLE ｡"
	DB	"     ENEMY     ｡"
	DB	"     BOSS !    ｡"
	DB	"  EXTRA STAGE  ｡"
	DB	"    STAGE: 1   ｡"
	DB	"    STAGE: 2   ｡"
	DB	"    STAGE: 3   ｡"
	DB	"    STAGE: 4   ｡"
	DB	"    STAGE: 5   ｡"
	DB	"    STAGE: 6   ｡"
	DB	"    --------   ｡"

TITLE_STR:
	DW	3800H
#IF exists _AILZ80ASM_
	charmap @MSX, "MSX_chara.json"
	DB	@MSX:"┌──　ＰＡＲＯＤＩＵＳ　：ＪＵＫＥ－ＢＯＸ　────────┐"
	DB	@MSX:"│　　　　　　　　　　　　　　　　　　　　　　　　　　　　　　│"
	DB	@MSX:"│　ＳＯＵＮＤ　－００－　　　　　　　ＮＯＷ　ＰＬＡＹＩＮＧ　│"
	DB	@MSX:"│　　　　　　　　　　　　　┌───────────────┐│"
	DB	@MSX:"│　ＭＵＳＩＣ　－００－　　│　　　　　　　　　　　　　　　││"
	DB	@MSX:"│　　　　　　　　　　　　　└───────────────┘│"
	DB	@MSX:"│　ＥＸＩＴ　　　　　　　　　（ＳＴＯＰ）：ＳＴＯＰ－ＢＧＭ　│"
	DB	@MSX:"└──────────────（ＨＯＭＥ）：ＦＡＤＥ－ＯＵＴ　┘"
	DB	@MSX:"｡"
#ELSE
	DB	"XWW PARODIUS :JUKE-BOX WWWWWWWWY"
	DB	"V                              V"
	DB	"V SOUND -00-       NOW PLAYING V"
	DB	"V             XWWWWWWWWWWWWWWWYV"
	DB	"V MUSIC -00-  V               VV"
	DB	"V             ZWWWWWWWWWWWWWWW[V"
	DB	"V EXIT         (STOP):STOP-BGM V"
	DB	"ZWWWWWWWWWWWWWW(HOME):FADE-OUT ["
	DB	"｡"
#ENDIF