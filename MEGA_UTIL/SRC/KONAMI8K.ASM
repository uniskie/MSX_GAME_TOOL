;***************************
; KONAMI 8K MEGAROM UTIL
;***************************

;BIOS LABELS for GAME UTILS
;	INCLUDE "BIOS-DEF.ASM"

;SIN10BAI_SEARCH 定義時
;	GET_KONAMI_ID ... 新10倍準拠のID取得

;SIN10BAI_SEARCH 未定義時
;	ROM_CHECK  ... BASIC用 シンプルなID判定
;	CHECK_ROM  ... シンプルなID判定

;--------------------------------------
; KONAMI MEGA-ROM BANK
;--------------------------------------
W_BANK:	EQU	0F0F1H	;(4) バンク番号保存ワークエリア
BANK0:	EQU	5000H	;4000H-5FFFH のバンク切り替えレジスタ
BANK1:	EQU	7000H	;6000H-7FFFH のバンク切り替えレジスタ
BANK2:	EQU	9000H	;8000H-9FFFH のバンク切り替えレジスタ
BANK3:	EQU	0B000H	;A000H-BFFFH のバンク切り替えレジスタ


;KONAMI GAME ID ADDRESS
ROM_BOOT_ADR:	EQU	4002H	;BOOT ADDRESS
GAME_ID_ADR:	EQU	4012H	;GAME_ID埋め込みタイプのアドレス

;--------------------------------------
; KONAMI SCC
;--------------------------------------
;KONAMI SCC COMPATIBLE MODE
SCCR_WAVE1:	equ 9800H	;ch1   波形テーブル 符号付8ビット値 32バイト 9800H-981FH
SCCR_WAVE2:	equ 9820H	;ch2   波形テーブル 符号付8ビット値 32バイト 9820H-983FH
SCCR_WAVE3:	equ 9840H	;ch3   波形テーブル 符号付8ビット値 32バイト 9840H-985FH
SCCR_WAVE4:	equ 9860H	;ch4&5 波形テーブル 符号付8ビット値 32バイト 9860H-987FH
SCCR_TONE1:	equ 9880H	;ch1 周波数分周比 12bit (2 bytes)
SCCR_TONE2:	equ 9882H	;ch2 周波数分周比 12bit (2 bytes)
SCCR_TONE3:	equ 9884H	;ch3 周波数分周比 12bit (2 bytes)
SCCR_TONE4:	equ 9886H	;ch4 周波数分周比 12bit (2 bytes)
SCCR_TONE5:	equ 9888H	;ch5 周波数分周比 12bit (2 bytes)
SCCR_VOL1:	equ 988AH	;ch1 音量 (1 byte)
SCCR_VOL2:	equ 988AH	;ch2 音量 (1 byte)
SCCR_VOL3:	equ 988AH	;ch3 音量 (1 byte)
SCCR_VOL4:	equ 988AH	;ch4 音量 (1 byte)
SCCR_VOL5:	equ 988AH	;ch5 音量 (1 byte)
SCCR_CHENA:	equ 988FH	;channel enable (bit0=ch1 ... bit4 = ch5)
SCCR_MIRROR:	equ 98A0H	;(mirrror of 9889-988FH)
SCCR_MODE:	equ 98E0H	;初期値は0 (98E1-98FF is mirror)
				;bit0: 分周比を4ビットにします。実際の分周比は、分周比レジスタの1／256になります。
				;bit1: 分周比を8ビットにします。ビット8～11は0になります。
				;bit5: 分周比レジスタに値を書き込むと、対応する波形データを先頭から再生しなおします。
				;bit6: 全チャンネルの波形データがローテートします。
				;      方向は、＋0にあったデータが＋1に移動します。
				;      ローテートする時間は、3．58MHz÷（分周比レジスタの値＋1）です。
				;      波形データメモリは全チャンネル書き込み禁止になります。
				;bit7: チャンネルDの波形データのみがローテートします。
				;      波形データメモリはチャンネルD，Eだけが書き込み禁止になります。
				;      このビットは、メガロムでのみ有効です。

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
ROMSLT:		DB	0	;0なら未検出
GAME_ID:	DW	0FFFFH	;FFFFなら未検出
HKPRADR:	DW	0	;検出したフック操作アドレス
				; LD ($FD9A),A 32 9A FD または
				; LD ($FD9F),A 32 9F FD の次の位置

PAGE1_SLOT:	EQU	EXPTBL	;PAGE1=BIOS ROM

;=============================================================================
IFDEF SIN10BAI_SEARCH
;=============================================================================

;--------------------------------------
; 新10倍タイプのGAME ID取得
; IN:	---
; OUT:	Cy=0:未検出、1:検出
;	未検出: (GAME_ID)=0FFFFH
;		ページ1のスロットはBIOSに戻す
;	検出時: A=スロット
;		(GAME_SLOT)=スロット
;		(GAME_ID)=XX07H ; RC-7XX (BCD値)
;	        (HKPRADR)=LD (H_KEYI),Aの次のアドレス
;		ページ1のスロットは切り替えたまま
; USE:	ALL
;--------------------------------------
GET_KONAMI_ID: 
	LD	BC,0400H	
	LD	HL,EXPTBL	

.CHECK_SLT_L:	
	PUSH	BC		
	PUSH	HL		
	LD	A,(HL)		
	BIT	7,A		
	JR	NZ,.CHECK_EXSLOT	

;基本スロット
	LD	B,C		
	CALL	.SKIP_SELF	
	JR	Z,.CHECK_SLT_NXT
	LD	A,C		
	CALL	.CHECK_GAME_ID	

.CHECK_SLT_NXT:	
	POP	HL		
	POP	BC		
	JR	C,.SLOT_DETECTED	
	INC	HL		
	INC	C		
	DJNZ	.CHECK_SLT_L	

;終わり
.SLOT_DETECTED:	
	PUSH	AF		
	JR	C,.SLOT_DETECTED_	;発見時はスロットを戻さない
;	LD	A,(SIN10_SLOT)	
	LD	A,(PAGE1_SLOT)	
	LD	H,40H		
	CALL	ENASLT		
.SLOT_DETECTED_:
	POP	AF		
	RET			

;拡張スロット
.CHECK_EXSLOT:	
	CALL	.CHK_EXSLOT	
	JR	.CHECK_SLT_NXT	

.CHK_EXSLOT:	
	AND	80H		
	OR	C		
	LD	B,04H		
.CHK_EXSLOT_L:	
	PUSH	BC		
	LD	B,A		
	CALL	.SKIP_SELF	
	JR	Z,.CHK_EXSLOT_1	
	LD	A,B		
	CALL	.CHECK_GAME_ID	
.CHK_EXSLOT_1:	
	POP	BC		
	RET	C		
	ADD	A,04H		
	DJNZ	.CHK_EXSLOT_L	
	RET			

;GAME_ID検索
.CHECK_GAME_ID:	
	LD	(GAME_SLOT),A	
	LD	H,40H		
	CALL	ENASLT		

;ROMヘッダ	AB検査
	LD	HL,(4000H)	
	LD	DE,4241H	
	RST	DCOMPR		
	JR	NZ,.NFND_GAME_ID	

;FD9FHかFD9AHの検索
	LD	HL,(4002H)	
	LD	E,9FH		;FD9Fの検索
	CALL	.FIND_VHOOK	
	RET	C		
	LD	HL,(4002H)	
	LD	E,9AH		;FD9Aの検索

;1BYTE検索＆次の1BYTEが0FDH	(FD9AHかFD9FHの検索用)
;HL=アドレス
;E=比較

.FIND_VHOOK:	
	LD	BC,0100H	
.FIND_VHOOK_L:	
	LD	A,E		
	CPIR			
	JR	NZ,.NFND_GAME_ID	
	JP	PO,.NFND_GAME_ID	
	LD	A,0FDH		
	CP	(HL)		
	JR	NZ,.FIND_VHOOK_L

	INC	HL
	LD	(HKPRADR),HL	; 32 9A FD または 32 9F FD の次のアドレス

;FD9AHかFD9FHを見つけた
;4010Hが'AB'か検査
	LD	HL,(4010H)	
	LD	DE,4241H	
	RST	DCOMPR		
	JR	Z,.F_4012_4013	
;4010Hが'CD'か
	LD	DE,4443H	
	RST	DCOMPR		
	JR	Z,.F_4012_4013	
;4010Hが'EF'か
	LD	DE,4645H	
	RST	DCOMPR		
	JR	Z,.F_4012_4013	

;4011Hが'E'で4013Hが'F'か
	LD	HL,(4011H)	
	LD	A,(4013H)	
	LD	H,A		
	RST	DCOMPR		
	JR	Z,.F_4011_4013	

;DE=	5000H	-	50FFH の SUM
	LD	DE,0000H	
	LD	HL,5000H	
	LD	B,00H		
.ADD_SUM_L:	
	LD	A,(HL)		
	ADD	A,E		
	LD	E,A		
	JR	NC,.ADD_SUM_1	
	INC	D		
.ADD_SUM_1:	
	INC	HL		
	DJNZ	.ADD_SUM_L	

;DE=	5000H	-	50FFH の SUM との 比較
;	PUSH	DE		
;	LD	A,(SIN10_SLOT)	
;	LD	H,40H		
;	CALL	ENASLT		
;	POP	DE		
	LD	IX,ROM_SUM_LIST	
;ROM_SUM_LIST:	EQU	44BEH

;マッチングリスト検索
.MATCH_SUM_L:	;LOOP
	LD	L,(IX+00H)	
	LD	H,(IX+01H)	
	LD	A,L		
	OR	H		
	JR	Z,.NFND_GAME_ID	
	RST	DCOMPR		
	JR	Z,.F_ON_LIST	
	INC	IX		
	INC	IX		
	INC	IX		
	INC	IX		
	JR	.MATCH_SUM_L	

;見つからなかった
.NFND_GAME_ID:	
	LD	HL,0FFFFH	
	LD	(GAME_ID),HL	
	LD	A,(GAME_SLOT)	
	AND	A		
	RET			;Cy=0

;4011Hが'E'で4013Hが'F'の場合
;4015Hが07、4017HがXX
.F_4011_4013:	
	LD	HL,(4015H)	
	LD	A,(4017H)	
	LD	H,A		
	JR	.FOUND_GAME_ID	

.F_ON_LIST:	
	LD	L,(IX+02H)	
	LD	H,(IX+03H)	

;->	HL = (DE - 45E3H)/19 * 2 + ROM_ID_LIST
	LD	DE,-45E3H
	ADD	HL,DE
	LD	BC,0
	LD	A,L
	OR	H
	JR	Z,.F_ON_LIST_1
	LD	DE,-19
.F_ON_LIST_L:
	INC	BC
	OR	A
	ADC	HL,DE
	JR	NZ,.F_ON_LIST_L
.F_ON_LIST_1:
	LD	L,C
	LD	H,B
	ADD	HL,HL
	LD	DE,ROM_ID_LIST
	ADD	HL,DE
;<-

	LD	E,(HL)		
	INC	HL		
	LD	D,(HL)		
	EX	DE,HL		
	JR	.FOUND_GAME_ID	

;BDC形式のGAME_IDが埋め込まれている
.F_4012_4013:	
	LD	HL,(4012H)	

;GAME_ID決定
.FOUND_GAME_ID:	
;スロットは戻さない
	LD	(GAME_ID),HL	
	LD	A,(GAME_SLOT)	
	SCF			
	RET			;Cy=1

;自分をスキップする
.SKIP_SELF:	
;	LD	A,(SIN10_SLOT)	
	LD	A,(PAGE1_SLOT)	;BIOSはスキップ
	BIT	7,A		
	JR	NZ,.SKIP_SELF_	
	BIT	7,B		
	RET	NZ		
	SUB	B		
	AND	03H		
	RET			
.SKIP_SELF_:	
	CP	B		
	RET			

; GAME_ID埋め込みが無いゲーム用：5000H～50FFhのサムで判定する為のデータ
ROM_SUM_LIST:
	; SUM, ID_ADR
	; sin10bai mem:44BEh rom +04BEh
	DW	5850H, 45E3H, 55A4H, 45E3H
	DW	6AA9H, 45F6H, 6649H, 45F6H
	DW	6CD5H, 4609H
	DW	6661H, 45F6H
	DW	6803H, 4609H
	DW	65C5H, 461CH, 6640H, 461CH, 5F17H, 461CH
	DW	5B7EH, 462FH, 5CE8H, 462FH, 5BE9H, 462FH
	DW	6A4CH, 4642H
	DW	5E17H, 4655H, 5E0FH, 4655H
	DW	77BCH, 4668H, 7A37H, 4668H, 7894H, 4668H
	DW	6D5BH, 467BH
	DW	774BH, 468EH, 7917H, 468EH, 7889H, 468EH
	DW	766BH, 46A1H, 779FH, 46A1H, 77D5H, 46A1H
	DW	6776H, 46B4H
	DW	5B72H, 46C7H, 5E21H, 46C7H, 4C65H, 46C7H
	DW	6761H, 46DAH, 6614H, 46DAH, 68C6H, 46DAH
	DW	47D4H, 46EDH
	DW	83A4H, 4700H
	DW	6C2CH, 4713H
	DW	72A2H, 4726H, 711CH, 4726H, 71A3H, 4726H
	DW	76DCH, 4739H
	DW	4695H, 474CH
	DW	5E1EH, 475FH, 5E35H, 475FH, 5EB0H, 475FH
	DW	6876H, 4772H, 57D8H, 4772H, 57EDH, 4772H
	DW	6D85H, 4785H, 6AB8H, 4785H
	DW	5D62H, 4798H, 643BH, 4798H
	DW	6518H, 4798H
	DW	719CH, 47ABH, 6B48H, 47ABH
	DW	68ADH, 47BEH, 678DH, 47BEH, 682EH, 47BEH
	DW	7402H, 47D1H
	DW	6504H, 47E4H, 6907H, 47E4H, 6B22H, 47E4H
	DW	87B8H, 47F7H
	DW	7991H, 480AH, 7936H, 480AH, 79C1H, 480AH, 7B24H, 480AH, 7AF5H, 480AH
	DW	85E4H, 4819H
	DW	0

ROM_ID_LIST:
	; sin10bai mem:45e3	rom +05E3 - +081C
	; 19byte * 30
	; COPY TO D300H AT START GAME
  	DB	7,00H;	, 00H, 00H, 00H-0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 40H,0E0H, 43H,0E0H, 46H,0E0H, 09H
  	DB	7,01H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 00H, 00H,0E0H,0E0H, 40H,0E0H, 43H,0E0H, 00H, 00H, 09H
  	DB	7,01H;	, 00H, 01H, 00H,0E0H, 00H, 00H, 00H, 00H,0E0H,0E0H, 40H,0E0H, 43H,0E0H, 00H, 00H, 09H
  	DB	7,02H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 40H,0E0H, 43H,0E0H, 46H,0E0H, 09H
  	DB	7,03H;	, 00H, 00H, 02H,0E0H, 00H,0E0H, 02H,0E0H, 00H, 00H, 11H,0E0H, 0BH,0E0H, 0EH,0E0H, 03H
  	DB	7,04H;	, 00H, 00H, 02H,0E0H, 00H,0E0H, 02H,0E0H, 00H, 00H, 11H,0E0H, 0BH,0E0H, 0EH,0E0H, 03H
  	DB	7,05H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 00H, 00H, 40H,0E0H, 46H,0E0H, 43H,0E0H, 09H
  	DB	7,06H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 00H, 00H, 40H,0E0H, 43H,0E0H, 46H,0E0H, 09H
  	DB	7,07H;	, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
  	DB	7,10H;	, 00H, 00H, 62H,0E1H, 1BH,0E0H, 00H, 00H, 16H,0E0H, 80H,0E0H, 83H,0E0H, 86H,0E0H, 96H
  	DB	7,11H;	, 00H, 00H, 62H,0E1H, 1BH,0E0H, 00H, 00H, 16H,0E0H, 80H,0E0H, 83H,0E0H, 86H,0E0H, 9FH
  	DB	7,12H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 46H,0E0H, 09H
  	DB	7,13H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 46H,0E0H, 09H
  	DB	7,14H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 46H,0E0H, 09H
  	DB	7,15H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 00H, 00H, 52H,0E0H, 44H,0E0H, 4AH,0E0H, 47H,0E0H, 09H
  	DB	7,16H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 50H,0E0H, 51H,0E0H, 46H,0E0H, 49H,0E0H, 4CH,0E0H, 09H
  	DB	7,17H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 00H, 00H, 80H,0E0H, 60H,0E0H, 63H,0E0H, 00H, 00H, 04H
  	DB	7,18H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 00H, 00H, 60H,0E0H, 55H,0E0H, 58H,0E0H, 00H, 00H, 04H
  	DB	7,20H;	, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
  	DB	7,21H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 00H, 00H, 04H
  	DB	7,23H;	, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
  	DB	7,24H;	, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
  	DB	7,25H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 00H, 00H, 04H
  	DB	7,27H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 49H,0E0H, 00H, 00H, 04H
  	DB	7,28H;	, 00H, 00H, 00H,0E0H, 01H,0E0H, 50H,0E0H, 53H,0E0H, 47H,0E0H, 4DH,0E0H, 00H, 00H, 04H
  	DB	7,29H;	, 00H, 00H, 00H,0E0H, 00H, 00H, 50H,0E0H, 51H,0E0H, 43H,0E0H, 46H,0E0H, 00H, 00H, 04H
  	DB	7,30H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 00H, 00H, 43H,0E0H, 3CH,0E0H, 3FH,0E0H, 00H, 00H, 03H
  	DB	7,31H;	, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H, 00H
  	DB	7,33H;	, 00H, 00H, 00H,0E0H, 02H,0E0H, 00H, 00H, 6AH,0E0H, 60H,0E0H, 66H,0E0H, 63H,0E0H, 04H
  	DB	7,44H;	,0A8H, 00H,0C0H, 04H, 11H,0C4H, 12H, 10H,0C4H, 05H,0C4H, 02H,0C0H, 07H, 47H,0B8H, 00H

;=============================================================================
ELSE;IFDEF SIN10BAI_SEARCH
;=============================================================================

;--------------------------------------
; シンプルなGAME ID判定 FOR BASIC
;（4012H埋め込みタイプ限定）
; (BASIC) A%=USR(GAME ROM ID)
;	OK:	A%=SLOT
;	NG:	A%=0
;--------------------------------------
ROM_CHK:
	INC	HL	; 
	INC	HL	; (DAC+2) INT ARGUMENT
	PUSH	HL
	CALL CHECK_ROM
	POP	HL	; (DAC+2) = SLOT
	LD	(HL),C
	INC	HL
	LD	(HL),B	;RET VAL
	LD	A,2
	LD	(VALTYP),A	;整数型に強制

	;RESTORE SLOT
	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT

	EI
	RET

;--------------------------------------
; シンプルなGAME ID判定
;（4012H埋め込みタイプ限定）
; IN:	(HL) = GAME_ID
; OUT:	NZ:Z
;	OK:NZ, C = SLOT
; USE:	AF,BC,DE
;	PAGE1 SLOT = CHENGED
;	NEED RESTORE SLOT AFTER CALL THIS
;--------------------------------------
CHECK_ROM:
;	PUSH	HL

	LD	A,(EXPTBL+1)
	BIT	7,A
	JR	NZ,CHECK_ROM_S1E
	LD	C,1
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
CHECK_ROM_S2:
	LD	A,(EXPTBL+1)
	BIT	7,A
	JR	NZ,CHECK_ROM_S2E
	LD	C,2
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
CHECK_ROM_NF:
;	LD	BC,0FFFFH	;-1
	LD	BC,0
CHECK_ROM_E:
;	POP	HL
	RET

CHECK_ROM_S1E:
	LD	C,81H	;1-0
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,85H	;1-1
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,89H	;1-2
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,8DH	;1-3
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	JR	CHECK_ROM_S2
CHECK_ROM_S2E:
	LD	C,82H	;2-0
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,86H	;2-1
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,8AH	;2-2
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	LD	C,8EH	;2-3
	CALL	SLTCHK
	JR	Z,CHECK_ROM_E
	JR	CHECK_ROM_NF

;--------------------------------------
; CHECK SLOT/EXP SLOT
; IN:	C=SLOT
;	(HL)=ROM ID
; OUT:	NZ:Z
;	OK:NZ, C = SLOT
; USE: AF,BC,DE
SLTCHK:
	PUSH	HL
	LD	HL,EXPTBL
	LD	A,C
	CALL	ADDHLA
	LD	A,(HL)	;EXPSLT CHECK
	POP	HL
	AND	80H
	LD	A,C
	JR	NZ,EXPSLTC	;EXPANDED
	LD	(ROMSLT),A
	JR	ROMCHK_S
; (CHECK EXP SLOT)
EXPSLTC:
	LD	B,04H
	OR	80H
	LD	C,A
EXPSLTL:
	LD	(ROMSLT),A
	CALL	ROMCHK_S
	RET	Z

	LD	A,C
	ADD	A,04H	;EXPSLT+1
	LD	C,A
	DJNZ	EXPSLTL
	OR	1
	RET

;--------------------------------------
;COMPARE KONAMI ROM ID (4012H)
; IN:	A=SLOT
;	(HL)=ROM ID
; OUT:	Z=NG
;	NZ=OK , C = SLOT
; USE: AF,BC,DE
ROMCHK_S:
	PUSH	HL
	LD	H,40H
	CALL	ENASLT

	LD	HL,(4000H)
	LD	DE,4241H	;'AB'
	RST	DCOMPR	;CALL	CPHLDE
	POP	HL
	JR	Z,ROMCHK_S2
	OR	E
	RET	;NZ=NG

ROMCHK_S2:
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	DEC	HL

	EX	DE,HL
	LD	BC,(GAME_ID_ADR)
	OR	A
	SBC	HL,BC
	EX	DE,HL

	LD	BC,(ROMSLT)
	LD	B,0
	RET	;Z=MATCH / NZ=NG

;=============================================================================
ENDIF;IFDEF SIN10BAI_SEARCH
;=============================================================================

