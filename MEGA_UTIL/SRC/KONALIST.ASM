;KONAMI_MSX2:	EQU	1	;MSX2用もリストに含むなら定義

KONAMI_ID_ISIZE:	EQU	KONAMI_ID_LIST_1 - KONAMI_ID_LIST	;28
KONAMI_ID_LIST:

		;初期の物はIDで判定できない
	DB	07H,00H,13,"Athletic Land              "	;RC 700 MSX1 "わんぱくアスレチック          " 
KONAMI_ID_LIST_1:
	DB	07H,01H,19,"Antarctic Adventure        "	;RC 701 MSX1 "けっきょく南極大冒険          " 
	DB	07H,02H,14,"Monkey Academy             "	;RC 702 MSX1 "モン太君のいち・に・さんすう  " 
	DB	07H,03H,17,"Time Pilot                 "	;RC 703 MSX1 "タイムパイロット              " 
	DB	07H,04H, 9,"Frogger                    "	;RC 704 MSX1 "フロッガー                    " 
	DB	07H,05H,11,"Super Cobra                "	;RC 705 MSX1 "スーパーコブラ                " 
	DB	07H,06H,18,"Konami's Billiards         "	;RC 706 MSX1 "コナミのビリヤード            " 
	DB	07H,07H,16,"Konami's Mahjong           "	;RC 707 MSX1 "コナミの麻雀道場              " 
	DB	07H,10H,15,"Hyper Olympic 1            "	;RC 710 MSX1 "ハイパーオリンピック1         " 
	DB	07H,11H,15,"Hyper Olympic 2            "	;RC 711 MSX1 "ハイパーオリンピック2         " 
	DB	07H,12H,14,"Circus Charlie             "	;RC 712 MSX1 "サーカスチャーリー            " 
	DB	07H,13H,12,"Magical Tree               "	;RC 713 MSX1 "マジカルツリー                " 
	DB	07H,14H,12,"Comic Bakery               "	;RC 714 MSX1 "I love 社会 ぽんぽこパン      " 
	DB	07H,15H,14,"Hyper Sports 1             "	;RC 715 MSX1 "ハイパースポーツ1             " 
	DB	07H,16H,18,"Cabbage Patch Kids         "	;RC 716 MSX1 "キャベッジパッチキッズ        " 
	DB	07H,17H,14,"Hyper Sports 2             "	;RC 717 MSX1 "ハイパースポーツ2             " 
	DB	07H,18H,11,"Hyper Rally                "	;RC 718 MSX1 "ハイパーラリー                " 
	DB	07H,20H,15,"Konami's Tennis            "	;RC 720 MSX1 "コナミのテニス                " 
	DB	07H,21H,10,"Sky Jaguar                 "	;RC 721 MSX1 "スカイジャガー                " 
	DB	07H,24H,17,"Konami's Baseball          "	;RC 724 MSX1 "コナミのベースボール          " 
	DB	07H,25H,14,"Yie Ar Kung Fu             "	;RC 725 MSX1 "イーアルカンフー              " 
	DB	07H,27H,13,"King's Valley              "	;RC 727 MSX1 "王家の谷                      " 
	DB	07H,28H,11,"Mopi Ranger                "	;RC 728 MSX1 "モピレンジャー                " 
	DB	07H,29H,07,"Pippols                    "	;RC 729 MSX1 "ピポルス                      " 
	DB	07H,30H,12,"Road Fighter               "	;RC 730 MSX1 "ロードファイター              " 
	DB	07H,31H,18,"Konami's Ping Pong         "	;RC 731 MSX1 "コナミのピンポン              " 
;KONAMI_ID_LIST_2:; ID埋め込みで検出できるものが出始めるのはこのあたりから
	DB	07H,32H,15,"Konami's Soccer            "	;RC 732 MSX1 "コナミのサッカー              " 
	DB	07H,33H,14,"Hyper Sports 3             "	;RC 733 MSX1 "ハイパースポーツ3             " 
	DB	07H,34H,11,"The Goonies                "	;RC 734 MSX1 "グーニーズ                    " 
	DB	07H,36H,15,"Konami's Boxing            "	;RC 736 MSX1 "コナミのボクシング            " 
	DB	07H,37H,16,"Yie Ar Kung Fu 2           "	;RC 737 MSX1 "イーガー皇帝の逆襲            " 
	DB	07H,39H,10,"Knightmare                 "	;RC 739 MSX1 "魔城伝説                      " 
	DB	07H,40H,08,"Twin Bee                   "	;RC 740 MSX1 "ツインビー                    " 
	DB	07H,42H, 7,"Gradius                    "	;RC 742 MSX1 "グラディウス                  " 
	DB	07H,43H,17,"Penguin Adventure          "	;RC 743 MSX1 "夢大陸アドベンチャー          " 
IFDEF KONAMI_MSX2
	DB	07H,44H,14,"Vampire Killer             "	;RC 744 MSX2 "悪魔城ドラキュラ              " 
	DB	07H,45H,11,"King Kong 2                "	;RC 745 MSX2 "キングコング2                 " 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,46H,06,"Q-Bert                     "	;RC 746 MSX1 "Qバート                       " 
IFDEF KONAMI_MSX2
	DB	07H,47H,17,"Hinotori Hououhen          "	;RC 747 MSX2 "火の鳥 鳳凰編                 " 
	DB	07H,48H,14,"Ganbare Goemon             "	;RC 748 MSX2 "がんばれゴエモン!からくり道中 " 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,49H,19,"The Maze of Galious        "	;RC 749 MSX1 "魔城伝説Ⅱガリウスの迷宮      " 
IFDEF KONAMI_MSX2
	DB	07H,50H,10,"Metal Gear                 "	;RC 750 MSX2 "メタルギア                    " 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,51H, 9,"Gradius 2                  "	;RC 751 MSX1 "グラディウス2                 " 
	DB	07H,52H,10,"F-1 Spirit                 "	;RC 752 MSX1 "F-1スピリット                 " 
IFDEF KONAMI_MSX2
	DB	07H,53H,20,"The Treasure of Usas       "	;RC 753 MSX2 "ウシャス                      " 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,54H,06,"Shalom                     "	;RC 754 MSX1 "シャロム 魔城伝説III 完結編   " 
IFDEF KONAMI_MSX2
	DB	07H,57H,20,"Clash Pennant Race 1       "	;RC 757 MSX2 "THEプロ野球 激突ペナントレース" 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,58H,10,"Salamander                 "	;RC 758 MSX1 "沙羅曼蛇                      " 
	DB	07H,59H,08,"Parodius                   "	;RC 759 MSX1 "パロディウス                  " 
	DB	07H,60H,22,"King's Valley 2 (MSX1)     "	;RC 760 MSX1 "エルギーザの封印 (MSX1)       " 
IFDEF KONAMI_MSX2
	DB	07H,61H,22,"King's Valley 2 (MSX2)     "	;RC 761 MSX2 "エルギーザの封印 (MSX2)       " 
ENDIF ;IFDEF KONAMI_MSX2
	DB	07H,62H,06,"Contra                     "	;RC 762 MSX2 "魂斗羅                        " 
	DB	07H,64H,27,"Gofer's Ambition Episode II"	;RC 764 MSX1 "ゴーファーの野望EPISODEII     " 
IFDEF KONAMI_MSX2
	DB	07H,65H,17,"Hai no Majutsushi          "	;RC 765 MSX2 "牌の魔術師                    " 
	DB	07H,66H,20,"Clash Pennant Race 2       "	;RC 766 MSX2 "激突ペナントレース2           " 
	DB	07H,67H,12,"Metal Gear 2               "	;RC 767 MSX2 "ソリッドスネークメタルギア2   " 
	DB	07H,68H,12,"Space Manbow               "	;RC 768 MSX2 "スペースマンボウ              " 
ENDIF ;IFDEF KONAMI_MSX2
KONAMI_ID_LIST_E:
    DB  0

;powershell
;		$C="Space Manbow               ";'{0:d2},"{1,-27}"' -f $C.Trim().Length, $C
;		12,"Space Manbow               "

