;--------------------------------------
;KONAMI_MSX1_ONLY:	EQU	1	;KONAMI MSX1  ソフトのみ
;KONAMI_MSX1_E000: 	EQU	1	;ワークエリアがE000H以上のソフトのみ
;KONAMI_LIST_LANG:	EQU	0	;0=JP / 1=EN / 2=SJIS
;--------------------------------------

MSX1:	EQU	0
MSX2:	EQU	1

KONAMI_ID_ISIZE:	EQU	KONAMI_ID_LIST_ - KONAMI_ID_LIST

#if !(exists KONAMI_LIST_LANG)
	#PRINT "KONAMI_LIST_LANGが定義されていないのでJP扱いにします。"
KONAMI_LIST_LANG:	EQU	0	;0=JP / 1=EN / 2=SJIS
#endif

#IF (exists KONAMI_MSX1_ONLY) || (exists KONAMI_MSX1_E000)
#ELSE
_USE_KONAMI_MSX2:	EQU	0XFFFF	;MSX2 用もリストに含むなら定義
#ENDIF

#IF KONAMI_LIST_LANG == 0 ;JP
KONAMILIST MACRO ID, MSXVER, RAM, JP_LEN,JP_STR, EN_LEN,EN_STR, SJIS_LEN, SJIS_STR
	DB	07H,(((ID-700) % 100) / 10)*16 + ((ID-700) % 10), (MSXVER << 7)+RAM, JP_LEN,JP_STR
	ENDM
KONAMI_TITLE_SIZE:	EQU	26
#ENDIF
#IF KONAMI_LIST_LANG == 1 ;EN
KONAMILIST MACRO ID, MSXVER, JP_LEN,JP_STR, EN_LEN,EN_STR, SJIS_LEN, SJIS_STR
	DB	07H,(ID % 100)*16 + (ID % 10), (MSXVER << 6)+RAM, EN_LEN,EN_STR
	ENDM
KONAMI_TITLE_SIZE:	EQU	27
#ENDIF
#IF KONAMI_LIST_LANG == 2 ;SJIS
KONAMILIST MACRO ID, MSXVER, JP_LEN,JP_STR, EN_LEN,EN_STR, SJIS_LEN, SJIS_STR
	DB	07H,(ID % 100)*16 + (ID % 10), (MSXVER << 6)+RAM, SJIS_LEN,SJIS_STR
	ENDM
KONAMI_TITLE_SIZE:	EQU	30
#ENDIF

KONAMI_ID_LIST:   ;                 "01234567890123456789012345"     "012345678901234567890123456"     "012345678901234567890123456789"
    KONAMILIST    700, MSX1,  8, 12,"ﾜﾝﾊﾟｸ ｱｽﾚﾁｯｸ              ", 13,"Athletic Land              ", 20,"わんぱくアスレチック          "
KONAMI_ID_LIST_:
    KONAMILIST    701, MSX1,  8, 20,"ｹｯｷｮｸ ﾅﾝｷｮｸ ﾀﾞｲﾎﾞｳｹﾝ      ", 19,"Antarctic Adventure        ", 20,"けっきょく南極大冒険          "
    KONAMILIST    702, MSX1,  8, 15,"ﾓﾝﾀ ﾉ ｲﾁ･ﾆ･ｻﾝｽｳ           ", 14,"Monkey Academy             ", 28,"モン太君のいち・に・さんすう  "
    KONAMILIST    703, MSX1,  8,  9,"ﾀｲﾑﾊﾟｲﾛｯﾄ                 ", 10,"Time Pilot                 ", 16,"タイムパイロット              "
    KONAMILIST    704, MSX1,  8,  6,"ﾌﾛｯｶﾞｰ                    ",  7,"Frogger                    ", 10,"フロッガー                    "
    KONAMILIST    705, MSX1,  8, 10,"ｽｰﾊﾟｰ ｺﾝﾄﾗ                ", 11,"Super Cobra                ", 14,"スーパーコブラ                "
    KONAMILIST    706, MSX1,  8, 13,"ｺﾅﾐ ﾉ ﾋﾞﾘﾔｰﾄﾞ             ", 18,"Konami's Billiards         ", 18,"コナミのビリヤード            "
    KONAMILIST    707, MSX1,  8, 20,"ｺﾅﾐ ﾉ ﾏｰｼﾞｬﾝ ﾄﾞｳｼﾞｮｳ      ", 16,"Konami's Mahjong           ", 16,"コナミの麻雀道場              "
    KONAMILIST    710, MSX1,  8, 13,"ﾊｲﾊﾟｰｵﾘﾝﾋﾟｯｸ1             ", 15,"Hyper Olympic 1            ", 21,"ハイパーオリンピック1         "
    KONAMILIST    711, MSX1,  8, 13,"ﾊｲﾊﾟｰｵﾘﾝﾋﾟｯｸ2             ", 15,"Hyper Olympic 2            ", 21,"ハイパーオリンピック2         "
    KONAMILIST    712, MSX1,  8,  9,"ｻｰｶｽﾁｬｰﾘｰ                 ", 14,"Circus Charlie             ", 18,"サーカスチャーリー            "
    KONAMILIST    713, MSX1,  8,  8,"ﾏｼﾞｶﾙﾂﾘｰ                  ", 12,"Magical Tree               ", 14,"マジカルツリー                "
    KONAMILIST    714, MSX1,  8, 10,"ﾎﾟﾝﾎﾟｺ ﾊﾟﾝ                ", 12,"Comic Bakery               ", 24,"I love 社会 ぽんぽこパン      "
    KONAMILIST    715, MSX1,  8, 11,"ﾊｲﾊﾟｰｽﾎﾟｰﾂ1               ", 14,"Hyper Sports 1             ", 17,"ハイパースポーツ1             "
    KONAMILIST    716, MSX1,  8, 15,"ｷｬﾍﾞｯｼﾞﾊﾟｯﾁｷｯｽﾞ           ", 18,"Cabbage Patch Kids         ", 22,"キャベッジパッチキッズ        "
    KONAMILIST    717, MSX1,  8, 11,"ﾊｲﾊﾟｰｽﾎﾟｰﾂ2               ", 14,"Hyper Sports 2             ", 17,"ハイパースポーツ2             "
    KONAMILIST    718, MSX1,  8,  8,"ﾊｲﾊﾟｰﾗﾘｰ                  ", 11,"Hyper Rally                ", 14,"ハイパーラリー                "
    KONAMILIST    720, MSX1,  8,  9,"ｺﾅﾐ ﾉ ﾃﾆｽ                 ", 15,"Konami's Tennis            ", 14,"コナミのテニス                "
    KONAMILIST    721, MSX1,  8,  9,"ｽｶｲｼﾞｬｶﾞｰ                 ", 10,"Sky Jaguar                 ", 14,"スカイジャガー                "
    KONAMILIST    723, MSX1,  8, 10,"ｺﾅﾐ ﾉ ｺﾞﾙﾌ                ", 13,"Konami's Golf              ", 14,"コナミのゴルフ                "
    KONAMILIST    724, MSX1,  8, 14,"ｺﾅﾐ ﾉ ﾍﾞｰｽﾎﾞｰﾙ            ", 17,"Konami's Baseball          ", 20,"コナミのベースボール          "
    KONAMILIST    725, MSX1,  8,  8,"ｲｰｱﾙｶﾝﾌｰ                  ", 14,"Yie Ar Kung Fu             ", 16,"イーアルカンフー              "
    KONAMILIST    727, MSX1,  8,  8,"ｵｳｹ ﾉ ﾀﾆ                  ", 13,"King's Valley              ",  8,"王家の谷                      "
    KONAMILIST    728, MSX1,  8,  9,"ﾓﾋﾟﾚﾝｼﾞｬｰ                 ", 11,"Mopi Ranger                ", 14,"モピレンジャー                "
    KONAMILIST    729, MSX1,  8,  6,"ﾋﾟﾎﾟﾙｽ                    ",  7,"Pippols                    ",  8,"ピポルス                      "
    KONAMILIST    730, MSX1,  8,  9,"ﾛｰﾄﾞﾌｧｲﾀｰ                 ", 12,"Road Fighter               ", 16,"ロードファイター              "
    KONAMILIST    731, MSX1,  8, 12,"ｺﾅﾐ ﾉ ﾋﾟﾝﾎﾟﾝ              ", 18,"Konami's Ping Pong         ", 16,"コナミのピンポン              "
    KONAMILIST    732, MSX1,  8, 10,"ｺﾅﾐ ﾉ ｻｯｶｰ                ", 15,"Konami's Soccer            ", 16,"コナミのサッカー              "
    KONAMILIST    733, MSX1,  8, 11,"ﾊｲﾊﾟｰｽﾎﾟｰﾂ3               ", 14,"Hyper Sports 3             ", 17,"ハイパースポーツ3             "
    KONAMILIST    734, MSX1,  8,  7,"ｸﾞｰﾆｰｽﾞ                   ", 11,"The Goonies                ", 10,"グーニーズ                    "
    KONAMILIST    736, MSX1,  8, 13,"ｺﾅﾐ ﾉ ﾎﾞｸｼﾝｸﾞ             ", 15,"Konami's Boxing            ", 18,"コナミのボクシング            "
    KONAMILIST    737, MSX1,  8, 20,"ｲｰｶﾞｰ ｺｳﾃｲ ﾉ ｷﾞｬｸｼｭｳ      ", 16,"Yie Ar Kung Fu 2           ", 18,"イーガー皇帝の逆襲            "
    KONAMILIST    739, MSX1,  8, 11,"ﾏｼﾞｮｳ ﾃﾞﾝｾﾂ               ", 10,"Knightmare                 ",  8,"魔城伝説                      "
    KONAMILIST    740, MSX1,  8,  6,"ﾂｲﾝﾋﾞｰ                    ",  8,"Twin Bee                   ", 10,"ツインビー                    "
    KONAMILIST    742, MSX1,  8,  8,"ｸﾞﾗﾃﾞｨｳｽ                  ",  7,"Gradius                    ", 12,"グラディウス                  "
    KONAMILIST    743, MSX1,  8, 16,"ﾕﾒﾀｲﾘｸ ｱﾄﾞﾍﾞﾝﾁｬｰ          ", 17,"Penguin Adventure          ", 20,"夢大陸アドベンチャー          "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    744, MSX2, 64, 14,"ｱｸﾏｼﾞｮｳ ﾄﾞﾗｷｭﾗ            ", 14,"Vampire Killer             ", 16,"悪魔城ドラキュラ              "
    KONAMILIST    745, MSX2, 64,  9,"ｷﾝｸﾞｺﾝｸﾞ2                 ", 11,"King Kong 2                ", 13,"キングコング2                 "
#endif
    KONAMILIST    746, MSX1,  8,  5,"Qﾊﾞｰﾄ                     ",  6,"Q-Bert                     ",  7,"Qバート                       "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    747, MSX2, 64, 11,"ﾋﾉﾄﾘ ﾎｳｵｳﾍﾝ               ", 17,"Hinotori Hououhen          ", 13,"火の鳥 鳳凰編                 "
    KONAMILIST    748, MSX2, 64, 25,"ｶﾞﾝﾊﾞﾚ ｺﾞｴﾓﾝ! ｶﾗｸﾘ ﾄﾞｳﾁｭｳ ", 14,"Ganbare Goemon             ", 29,"がんばれゴエモン!からくり道中 "
#endif
    KONAMILIST    749, MSX1,  8, 26,"ﾏｼﾞｮｳﾃﾞﾝｾﾂII ｶﾞﾘｳｽ ﾉ ﾒｲｷｭｳ", 19,"The Maze of Galious        ", 24,"魔城伝説Ⅱガリウスの迷宮      "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    750, MSX2, 64,  6,"ﾒﾀﾙｷﾞｱ                    ", 10,"Metal Gear                 ", 10,"メタルギア                    "
#endif
    KONAMILIST    751, MSX1,  8,  9,"ｸﾞﾗﾃﾞｨｳｽ2                 ",  9,"Gradius 2                  ", 13,"グラディウス2                 "
    KONAMILIST    752, MSX1,  8,  9,"F-1ｽﾋﾟﾘｯﾄ                 ", 10,"F-1 Spirit                 ", 13,"F-1スピリット                 "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    753, MSX2, 64,  4,"ｳｼｬｽ                      ", 20,"The Treasure of Usas       ",  8,"ウシャス                      "
#endif
    KONAMILIST    754, MSX1,  8, 25,"ｼｬﾛﾑ ﾏｼﾞｮｳﾃﾞﾝｾﾂIII ｶﾝｹﾂﾍﾝ ",  6,"Shalom                     ", 27,"シャロム 魔城伝説III 完結編   "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    757, MSX2, 64, 26,"THE ﾌﾟﾛﾔｷｭｳ ｹﾞｷﾄﾂ ﾍﾟﾅﾝﾄﾚｰｽ", 20,"Clash Pennant Race 1       ", 30,"THEプロ野球 激突ペナントレース"
#endif
#if !(exists KONAMI_MSX1_E000)
    KONAMILIST    758, MSX1, 16,  6,"ｻﾗﾏﾝﾀﾞ                    ", 10,"Salamander                 ",  8,"沙羅曼蛇                      "
#endif
    KONAMILIST    759, MSX1,  8,  8,"ﾊﾟﾛﾃﾞｨｳｽ                  ",  8,"Parodius                   ", 12,"パロディウス                  "
    KONAMILIST    760, MSX1,  8, 21,"ｴﾙｷﾞｰｻﾞ ﾉ ﾌｳｲﾝ (MSX1)     ", 22,"King's Valley 2 (MSX1)     ", 23,"エルギーザの封印 (MSX1)       "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    761, MSX2, 64, 21,"ｴﾙｷﾞｰｻﾞ ﾉ ﾌｳｲﾝ (MSX2)     ", 22,"King's Valley 2 (MSX2)     ", 23,"エルギーザの封印 (MSX2)       "
    KONAMILIST    762, MSX2, 64,  4,"ｺﾝﾄﾗ                      ",  6,"Contra                     ",  6,"魂斗羅                        "
#endif
    KONAMILIST    764, MSX1,  8, 24,"ｺﾞｰﾌｧｰ ﾉ ﾔﾎﾞｳ Episode II  ", 27,"Gofer's Ambition Episode II", 25,"ゴーファーの野望EPISODEII     "
#if exists _USE_KONAMI_MSX2
    KONAMILIST    765, MSX2, 64, 11,"ﾊｲ ﾉ ﾏｼﾞｭﾂｼ               ", 17,"Hai no Majutsushi          ", 10,"牌の魔術師                    "
    KONAMILIST    766, MSX2, 64, 16,"ｹﾞｷﾄﾂ ﾍﾟﾅﾝﾄﾚｰｽ 2          ", 20,"Clash Pennant Race 2       ", 19,"激突ペナントレース2           "
    KONAMILIST    767, MSX2, 64, 17,"ｿﾘｯﾄﾞｽﾈｰｸ ﾒﾀﾙｷﾞｱ2         ", 12,"Metal Gear 2               ", 27,"ソリッドスネークメタルギア2   "
    KONAMILIST    768, MSX2, 64, 10,"ｽﾍﾟｰｽﾏﾝﾎﾞｳ                ", 12,"Space Manbow               ", 16,"スペースマンボウ              "
#endif
KONAMI_ID_LIST_E:
    DB  0

