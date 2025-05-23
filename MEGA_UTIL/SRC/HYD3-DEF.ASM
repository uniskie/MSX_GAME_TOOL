;-*- tab-width: 8 -*-
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

#pragma once

;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;********************************************************
; HYD3-EXP LABELS
; BIOSの空きワークエリアを使用する
;********************************************************
;EXPADR:	EQU	MCLTAB	; NG
EXPADR:		EQU	VOICAQ	;Program Area 0F975H - 0FAF4H
STACKA:		EQU	VCBC
STACKLIM:	EQU	VCBA	; STACK UNDER LIMIT
STKMIN:		EQU	32+32	;Z80 REG=12*2=24

; (HYD3-EXP) ROM BANK No. for CONTINUE 4bytes
BANK_0:	EQU	VCBC + 0	;DB	0
BANK_1:	EQU	VCBC + 1	;DB	0
BANK_2:	EQU	VCBC + 2	;DB	0
BANK_3:	EQU	VCBC + 3	;DB	0
;	VCBC=37/4

; (HYD3-EXP) WAIT CONTROL OPTION 4bytes
BASVER:	EQU	VCBC + 4	;DW HYD3STRT VER for check
EXPVER:	EQU	VCBC + 6	;DW HYD3-EXP VER for check
MSXVER:	EQU	VCBC + 8	;DB HYDLIDE3 MSX1/2 VERSION
;	VCBC=37/4+5=10

; (HYD3-EXP) WAIT CONTROL OPTION  3bytes
;WAITTM:	EQU	VCBC +10	;DW WAIT
CAPSTA:	EQU	VCBC +12	;DB CAPS
;	VCBC=37/10+2+1=13

;PADDING EQU	VCBC +13	;DBFIL 7
;	VCBC=37/13+7=20

EXPSP:	EQU	VCBC +20	;DW SP ADDRESS for CONTINUE
;	VCBC=37/20+2=22

;PADDING DB	0
;	VCBC=37/22+1=23

; (HYD3-EXP) PSG REG SAV
PSG_SV:	EQU	VCBC +23	;PSG REG=13bytes+1bytes
;	VCBC=37/23+13+1=37
;--------------------------------------

#IF PSG_SV<=CAPSTA 
	#ERROR
#ENDIF

#IF (PSG_SV+14)>(VCBC+VCBSZ)
	#ERROR
#ENDIF

;********************************************************
;バンク識別用アドレス
;（BANK先頭8byteは0などで埋まっている事が多いのでずらす)
;********************************************************
BANKPG0:	EQU	4000H		;ページ0 BANKアドレス
BANKSIZ:	EQU	2000H		;BANKサイズ
BANKNUM:	EQU	40H		;BANK数 0-3FH
IDDSIZE:	EQU	6		;BANK識別データ サイズ
;IDDBAS0:	EQU	4008H		;ページ0 BANK識別データ 開始アドレス NG:28000Hのバンクが誤判定で0になる
IDDBAS0:	EQU	4008H		;ページ0 BANK識別データ 開始アドレス OK?:28008H が0以外なので
IDDBAS1:	EQU	IDDBAS0+BANKSIZ	;ページ1 BANK識別データ 開始アドレス
IDDBAS2:	EQU	IDDBAS1+BANKSIZ	;ページ2 BANK識別データ 開始アドレス
IDDBAS3:	EQU	IDDBAS2+BANKSIZ	;ページ3 BANK識別データ 開始アドレス
