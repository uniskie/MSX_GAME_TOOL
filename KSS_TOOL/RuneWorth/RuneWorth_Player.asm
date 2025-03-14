;https://github.com/AILight/AILZ80ASM

data_addr:  equ 0x2000

BASE: equ 0x7000-0x10

	db	'KSCC'		; +0: マジックコード
	dw	LOAD+BASE	; +4: ロードアドレス    （Z80アドレス空間）
	dw	CODE_SIZE-0x10	; +6: 初期データの長さ
	dw	INIT+BASE	; +8: 初期化処理アドレス（Z80アドレス空間）
	dw	PLAY+BASE	; +a: 再生処理アドレス  （Z80アドレス空間）
	db	0x00		; +c: 開始バンク番号
	db	6		; +d: b7=0:16k bank / 6 block
	db	0x00		; +e: (reserve)
	db	0x05		; +f: 00001001
				;         xx: ------01 = FMPACを使う
				;       x  x: ----1-0- = MSX-AUDIOを使う

LOAD:
	ret

PLAY:
	db	0xc3
PLAY_ADDR:
	dw	LOAD+BASE


INIT:
	ld	ix,TABLE+BASE
	ld	h,0x00
	ld	l,0x1e+0x1e
LP:
	bit	7,(ix+0)
	jr	NZ,ERR
	and	a
	jr	z,GO
	dec	a

	push	af
	ld	a,l
	add	a,(ix+0)
	ld	l,a
	jr	nc,FF0
	inc	h
FF0:
	pop	af
	inc	ix
	jr	LP

ERR:
	ld	a,0xC9
	ld	(PLAY+BASE),a
	ret

GO:

;copy data
	ld	de,data_addr
	ld	b,(ix+0)
	ld	c,0
	call	COPY+BASE

;copy driver
	ld	a,(data_addr)
	cp	0x10
	jr	z,USEFMPAC

	ld	hl,0x001e
	ld	de,0x0100
	ld	bc,0x1e00
	call	COPY+BASE
	;remap ram
	ld	a,0x7f
	out	(0xfe),a
	ld	hl,0x0100
	ld	(PLAY_ADDR+BASE),hl
	call	0x0103
	xor	a
	ld	b,a
	ld	hl,0x2000
	jp	0x0106

USEFMPAC:

	ld	hl,0x0000
	ld	de,0x0100
	ld	bc,0x1e00
	call	COPY+BASE
	;remap ram
	ld	a,0x7f
	out	(0xfe),a
	ld	hl,0x020c
	ld	(PLAY_ADDR+BASE),hl
	;ld	a,0x80
	;ld	(0xfcc1),a
	ld	a,0x00
	ld	(0x0426),a
	call	0x0200
	xor	a
	ld	b,a
	ld	hl,0x2000
	jp	0x0106

COPY:
	push	bc
	push	hl
	ld	a,h
	ld	b,l
	rl	b
	rl	a
	rl	b
	rl	a
	out	(0xfe),a
	ld	a,l
	and	0x3f
	or	0x80
	ld	h,a
	ld	l,0x00
	ld	bc,0x0100
	ldir
	pop	hl
	pop	bc
	inc	hl
	dec	b
	jr	nz,COPY
	ret

TABLE:
;psgdrv4 (RAM:0100-1EFF)  +7EBD size:1E00
;oplldrv4 (RAM:0100-1EFF) +6E00 size:1E00

;+08c00-0a400 (01800 bytes) DEMO DISK OPENING MUSIC
	db	0x02	;08C 00
	db	0x04	;08E
	db	0x0A	;092
	db	0x08	;098

;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC
	db	0x02	;3b8 04
	db	0x02	;3ba
	db	0x04	;3bc
	db	0x04	;3c0
	db	0x08	;3c4 08
	db	0x06	;3cc
	db	0x04	;3d2
	db	0x04	;3d6
	db	0x06	;3da 0c
	db	0x04	;3e0
	db	0x06	;3e4
	db	0x04	;3ea
	db	0x06	;3ee 10
	db	0x06	;3f4
	db	0x04	;3fa
	db	0x02	;3fe
	db	0x02	;400 14
	db	0x02	;402
	db	0x02	;404
	db	0x02	;406
	db	0x04	;408 18
	db	0x04	;40c
	db	0x04	;410
	db	0x04	;414
	db	0x04	;418 1c
	db	0x04	;41c
	db	0x02	;420
	db	0x02	;422
	db	0x02	;424 20
	db	0x02	;426

;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC
	db	0x08	;55a
	db	0x06	;562
	db	0x06	;568 24
	db	0x04	;56e
	db	0x02	;572
	db	0x02	;574
	db	0x04	;576 28
	db	0x04	;57a
	db	0x04	;57e
	db	0x02	;582
	db	0x04	;584 2c
	db	0x04	;588
	db	0x04	;58c
	db	0x04	;590
	db	0x04	;594 30
	db	0x04	;598
;	db	0x04	;59c ;重複データ

;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC
	db	0x04	;4ca
	db	0x04	;4ce
	db	0x02	;4d2 34
	db	0x02	;4d4
	db	0x04	;4d6
	db	0x04	;4da
	db	0x04	;4de 38
	db	0x04	;4e2
	db	0x06	;4e6
	db	0x04	;4ec
	db	0x04	;4f0 3c
	db	0x04	;4f4
	db	0x04	;4f8
	db	0x04	;4fc
	db	0x06	;500 40
	db	0x04	;506
	db	0x06	;50a
	db	0x06	;510
	db	0x06	;516 44
	db	0x04	;51c

;220-238 +018 DEMO DISK ENDING MUSIC
	db	0x08	;220
	db	0x06	;228
	db	0x06	;22E 48
	db	0x04	;234

	db	0x80

CODE_SIZE:



;0000 4BYTES マジック 'KSCC'
;0004 WORD(LE) Z80アドレス空間のロードアドレス(0000-FFFF)
;0006 WORD(LE) 初期データの長さ（バイト単位、0000-FFFF）
;0008 WORD(LE) Z80アドレス空間の初期化アドレス(0000-FFFF)
;000A WORD(LE) Z80アドレス空間の再生アドレス(0000-FFFF)
;000C BYTE 開始(オフセット) バンク番号
;000D BYTE 8/16kbytesバンク追加データブロックサポート
;                   ビット0-6: 8/16kバイトのバンクされた追加データブロックの数
;                   ビット7: 設定されている場合、この曲はKSS 8kマッパーを使用します
;000E 拡張用に予約されたバイト（00hである必要があります）
;000F BYTE 追加サウンドチップのサポート
;                   ビット 0: 設定されている場合、この曲は FMPAC (ビット 1 = 0)、FMUNIT (ビット 1 = 1) を使用します。
;                   ビット1: 設定されている場合、この曲はSN76489を使用します
;                   ビット 2: 設定されている場合、この曲は RAM(ビット 1=0)、GG ステレオ(ビット 1=1) を使用します。
;                   ビット 3: 設定されている場合、この曲は MSX-AUDIO (ビット 1 = 0)、RAM (ビット 1 = 1) を使用します。
;                   ビット 4-7: 予約済み。0 でなければなりません
;0010 n BYTES 指定長さ初期データ
;
;0010+n 16kBYTES 最初の16kブロックの追加データ(オプション)
;4010+n 16kBYTES 2番目の16kブロックの追加データ(オプション)
;...
;
;0010+n 8kBYTES 追加データの最初の8kブロック(オプション)
;2010+n 8kBYTES 2番目の8kブロックの追加データ(オプション)
;
;...
;
;[KSS 16k マッパー メモリ マップ]
;
;0000
; | RAM(読み取り/書き込み)
;7FFF
;8000
; | 16k バンク ROM(R)、SCC/SCC+ メモリ マップ I/O(W:9800-988F、B800-B8AF)
;最高
;C000
; | RAM(読み取り/書き込み)
;えーーーー
;
;[KSS 16k マッパー RAM モード メモリ マップ]
;
;0000
; | RAM(読み取り/書き込み)
;7FFF
;8000
; | RAM(R/W:初期データ)、ROM(R:追加データ)、SCC/SCC+(W:追加データ)
;最高
;C000
; | RAM(読み取り/書き込み)
;えーーーー
;
;[KSS 8k マッパー メモリ マップ]
;
;0000
; | RAM(読み取り/書き込み)
;7FFF
;8000
; | 最初の 8k バンク ROM(R)、選択(W:9000)、SCC メモリ マップ I/O(W:9800-988F)
;9FFF
;A000
; | 2番目の8kバンクROM(R)、選択(W:B000)、SCC+メモリマップI/O(W:B800-B8AF)
;最高
;C000
; | RAM(読み取り/書き込み)
;えーーーー
;
;[KSS I/Oマップ]
;
;06 GGステレオポート(W)
;A0 AY3-8910 アドレスポート(W)
;A1 AY3-8910 データポート(W)
;A2 AY3-8910 読み取りポート(R)
;7C FMPACアドレスポート(W)
;7D FMPACデータポート(W)
;7E SN76489 ポート(W)
;7F SN76489 ポート(W)(7E のミラー)
;C0 MSX-AUDIOアドレスポート(W)
;C1 MSX-AUDIOデータポート(W)
;F0 FMUNITアドレスポート(W)
;F1 FMUNITデータポート(W)
;FE KSS 16kバイトバンクROM選択ポート(W)
;         不正な値が書き込まれると、初期領域がマップされます。
;         (開始番号) <= (有効な値) < (開始番号) + (ブロック数)
;
;
;[読み込みプロセス]
;
;1) すべての Z80 アドレス空間 (0000h-ffffh) をクリアします。
;2) 0000h-3fffh の RAM を c9h('ret' コード) で埋めます。
;3) 0001hからWRTPSGコード(d3h、a0h、f5h、7Bh、d3h、a1h、f1h、c9h)を書き込みます。
;4) 0093hからWRTPSGエントリコード(c3h,01h,00h)を書き込みます。
;5) 0009hからRDPSGコード(d3h、a0h、dbh、a2h、c9h、)を書き込みます。
;6) 0096hからRDPSGエントリコード(c3h,09h,00h)を書き込みます。
;7) データを初期 Z80 アドレス空間の init アドレスにロードします。
;
;
;[初期化処理]
;
;1) 「ロードプロセス」で Z80 アドレス空間を初期化します。
;2) 希望の曲のアキュムレータを設定します。
;3) スタックポインタを f380h に初期化します。
;4) init アドレスを呼び出します。
;
;
;【プレイの流れ】
;
;1) 60Hzで再生アドレスを呼び出します。

