;**** for Rune Worth Music Disk (MSX2) ****

;https://github.com/AILight/AILZ80ASM

KSS_BANK_IO:	equ 0xfe

data_addr:	equ 0x2000
driver_size:	equ 0x1100
driver_szb:	equ (driver_size / 0x100)

; T&E BGM Driver X (for PSG/OPLL *mdt file)
; PSY-O-BLADE / LAYDOCK2 / UNDEADLINE / Rune Worth
; ( ** Gratest Driver is different driver)
driver_base:	equ 0x0100	;driver address (Z80)
driver_intr:	equ driver_base + 0x00 ; interrupt rutine for playing
driver_init:	equ driver_base + 0x03 ; initialize
			; (0x0426) == 0 : skip OPLL check (check and swap OPLL/PSG driver)
driver_play:	equ driver_base + 0x06 ; start play
			; in: hl = data address
			;     a = loop count (0=infinite loop)
			;     b = fade-in wait (unit: 1/60 sec) (each one volume)
driver_stop:	equ driver_base + 0x09 ; stop play
driver_fadeout:	equ driver_base + 0x0C ; fade-out
			; in: b = fade-out wait (unit: 1/60 sec) (each one volume)

BASE:	equ 0x7000

	org	BASE-0x10

	db	'KSCC'		; +0: KSS Magic code
	dw	LOAD		; +4: Initial_load z80 address
	dw	TERM-BASE	; +6: Initial_load size
	dw	INIT		; +8: Play_init call z80 address (set track number)
	dw	PLAY		; +a: Play_loop call z80 address (1/60sec. vsync)
	db	0x00		; +c: initial memory bank no.
	db	6		; +d: b7=0:16k bank, 6 block
	db	0x00		; +e: (reserve)
	db	0x05		; +f: 00001001
				;         xx: ------01 = FMPAC
				;       x  x: ----1-0- = MSX-AUDIO

LOAD:
	ret

PLAY:
	db	0xc3
PLAY_ADDR:
	dw	LOAD

INIT:
	ld	ix,TABLE
	ld	h,0x00
	ld	l,driver_szb+driver_szb	;driver size(opll+psg) / 256
LP:
	bit	7,(ix+0)
	jr	NZ,ERR
	and	a
	jr	z,GO
	dec	a

	push	af
	ld	a,l
	add	a,(ix+0)		;add offset
	ld	l,a
	jr	nc,FF0
	inc	h
FF0:
	pop	af
	inc	ix
	inc	ix
	jr	LP

ERR:
	ld	a,0xC9
	ld	(PLAY),a
	ret

GO:

;copy data
					;hl = address / 256
	ld	de,data_addr
	ld	b,(ix+0)		;bc = size
	ld	c,0
	
	call	COPY

;copy driver
	ld	a,(data_addr)
	cp	0x10
	jr	z,USE_OPLLDRV

USE_PSGDRV:
	ld	hl,driver_szb		;hl = address / 256
	ld	de,driver_base
	ld	bc,driver_size
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,driver_intr
	ld	(PLAY_ADDR),hl
	call	driver_init

	ld	a,(ix+1)		;a = loop count (0=infinite loop)
	ld	b,0			;b = fade-in wait (unit: 1/60 sec) (each one volume)
	ld	hl,data_addr
	jp	driver_play

USE_OPLLDRV:

	ld	hl,0x0000		;hl = address / 256
	ld	de,driver_base
	ld	bc,driver_size
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,driver_intr
	ld	(PLAY_ADDR),hl
	;ld	a,0x80
	;ld	(0xfcc1),a
	ld	a,0x00
	ld	(0x0426),a		;skip OPLL check
	call	driver_init
	ld	a,(ix+1)		;a = loop count (0=infinite loop)
	ld	b,0			;b = fade-in wait (unit: 1/60 sec) (each one volume)
	ld	hl,data_addr
	jp	driver_play

COPY:	
;hl = src address / 256
;de = dest address
;hl = copy size
	push	bc
	push	hl
	ld	a,h
	ld	b,l
	rl	b
	rl	a
	rl	b
	rl	a
	out	(KSS_BANK_IO),a
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
;psgdrv4 (RAM:0100-11FF)  +7EBD size:1100
;oplldrv4 (RAM:0100-11FF) +6E00 size:1100

;+08c00-0a400 (01800 bytes) START DISK OPENING MUSIC
	db	0x02, 0	;S 08c00 #00 [F] 01. サリスの滅亡
	db	0x04, 0	;S 08e00 #01 [P] 01. サリスの滅亡
	db	0x0A, 0	;S 09200 #02 [F] 02. ルーンワースのテーマ
	db	0x08, 0	;S 09C00 #03 [P] 02. ルーンワースのテーマ

;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC
	db	0x02, 0	;A 3b800 #04 [F] 03. 旅立ち
	db	0x02, 0	;A 3ba00 #05 [P] 03. 旅立ち
	db	0x04, 0	;A 3bc00 #06 [F] 14. 死んでしまった
	db	0x04, 0	;A 3c000 #07 [P] 14. 死んでしまった
	db	0x08, 0	;A 3c400 #08 [F] 06. ウェイデニッツ公国
	db	0x06, 0	;A 3cc00 #09 [P] 06. ウェイデニッツ公国
	db	0x04, 0	;A 3d200 #10 [F] 12. もったいない
	db	0x04, 0	;A 3d600 #11 [P] 12. もったいない
	db	0x06, 0	;A 3da00 #12 [F] 11. 祈り
	db	0x04, 0	;A 3e000 #13 [P] 11. 祈り
	db	0x06, 0	;A 3e400 #14 [F] 13. 5時からの男のために
	db	0x04, 0	;A 3ea00 #15 [P] 13. 5時からの男のために
	db	0x06, 0	;A 3ee00 #16 [F] 17. URE-P
	db	0x06, 0	;A 3f400 #17 [P] 17. URE-P
	db	0x04, 0	;A 3fa00 #18 [F] 15. KANA-P
	db	0x02, 0	;A 3fe00 #19 [P] 15. KANA-P
	db	0x02, 1	;A 40000 #20 [F] 36. * GAME OVER
	db	0x02, 1	;A 40200 #21 [P] 36. * GAME OVER
	db	0x02, 0	;A 40400 #22 [F] 16. もっと KANA-P
	db	0x02, 0	;A 40600 #23 [P] 16. もっと KANA-P
	db	0x04, 0	;A 40800 #24 [F] 19. うろわば！
	db	0x04, 0	;A 40c00 #25 [P] 19. うろわば！
	db	0x04, 0	;A 41000 #26 [F] 20. 神々のガミガミ
	db	0x04, 0	;A 41400 #27 [P] 20. 神々のガミガミ
	db	0x04, 0	;A 41800 #28 [F] 32. 限りなき戦い
	db	0x04, 0	;A 41c00 #29 [P] 32. 限りなき戦い
	db	0x02, 0	;A 42000 #30 [F] 38. * ファンファーレ(終わり際がおかしいのでループさせた方が安全)
	db	0x02, 1	;A 42200 #31 [P] 38. * ファンファーレ
	db	0x02, 1	;A 42400 #32 [F] 39. * リカルトの竪琴
	db	0x02, 1	;A 42600 #33 [P] 39. * リカルトの竪琴

;+00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2
	db	0x01, 0	;A 00400 #34 [F] 37. * 宝箱ゲット(終わり際がおかしいのでループさせた方が安全)
	db	0x01, 0	;A 00500 #35 [F] 21. 危険がアブナイ
	db	0x01, 1	;A 00600 #36 [P] 37. * 宝箱ゲット
	db	0x01, 0	;A 00700 #37 [P] 21. 危険がアブナイ

;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC
	db	0x08, 0	;A 55a00 #38 [F] 04. ザノバ砦
	db	0x06, 0	;A 56200 #39 [P] 04. ザノバ砦
	db	0x06, 0	;A 56800 #40 [F] 05. 神聖サイア王国
	db	0x04, 0	;A 56e00 #41 [P] 05. 神聖サイア王国
	db	0x02, 0	;A 57200 #42 [F] 08. シャタパーサ連邦
	db	0x02, 0	;A 57400 #43 [P] 08. シャタパーサ連邦
	db	0x04, 0	;A 57600 #44 [F] 18. ミリムはオ・ト・ナ
	db	0x04, 0	;A 57a00 #45 [P] 18. ミリムはオ・ト・ナ
	db	0x04, 0	;A 57e00 #46 [F] 10. おーたま
	db	0x02, 0	;A 58200 #47 [P] 10. おーたま
	db	0x04, 0	;A 58400 #48 [F] 26. サータルスの導き
	db	0x04, 0	;A 58800 #49 [P] 26. サータルスの導き
	db	0x04, 0	;A 58c00 #50 [F] 27. 無法都市
	db	0x04, 0	;A 59000 #51 [P] 27. 無法都市
	db	0x04, 0	;A 59400 #52 [F] 28. ラマスカエル燃ゆ
	db	0x04, 0	;A 59800 #53 [P] 28. ラマスカエル燃ゆ

;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC
	db	0x04, 0	;B 4ca00 #54 [F] 07. バハマーン神国
	db	0x04, 0	;B 4ce00 #55 [P] 07. バハマーン神国
	db	0x02, 0	;B 4d200 #56 [F] 09. ウェーデル山脈
	db	0x02, 0	;B 4d400 #57 [P] 09. ウェーデル山脈
	db	0x04, 0	;B 4d600 #58 [F] 22. 永久凍土
	db	0x04, 0	;B 4da00 #59 [P] 22. 永久凍土
	db	0x04, 0	;B 4de00 #60 [F] 23. オールマムの野望
	db	0x04, 0	;B 4e200 #61 [P] 23. オールマムの野望
	db	0x06, 0	;B 4e600 #62 [F] 24. 戦慄の魔導士
	db	0x04, 0	;B 4ec00 #63 [P] 24. 戦慄の魔導士
	db	0x04, 0	;B 4f000 #64 [F] 25. あやかしの塔
	db	0x04, 0	;B 4f400 #65 [P] 25. あやかしの塔
	db	0x04, 0	;B 4f800 #66 [F] 29. エリースの涙
	db	0x04, 0	;B 4fc00 #67 [P] 29. エリースの涙
	db	0x06, 0	;B 50000 #68 [F] 30. 暗殺魔術団ヴィーフォ
	db	0x04, 0	;B 50600 #69 [P] 30. 暗殺魔術団ヴィーフォ
	db	0x06, 0	;B 50a00 #70 [F] 31. 暗黒からの脱出
	db	0x06, 0	;B 51000 #71 [P] 31. 暗黒からの脱出
	db	0x06, 0	;B 51600 #72 [F] 33. 邪神復活
	db	0x04, 0	;B 51c00 #73 [P] 33. 邪神復活

;+22000-23800 (01800 bytes) START DISK ENDING MUSIC
	db	0x08, 0	;S 22000 #74 [F] 34. やすらぎ
	db	0x06, 0	;S 22800 #75 [P] 34. やすらぎ
	db	0x06, 0	;S 22E00 #76 [F] 35. 明日がふり返る
	db	0x04, 0	;S 23400 #77 [P] 35. 明日がふり返る

	db	0x80

TERM:



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
;BFFF
;C000
; | RAM(読み取り/書き込み)
;FFFF
;
;[KSS 16k マッパー RAM モード メモリ マップ]
;
;0000
; | RAM(読み取り/書き込み)
;7FFF
;8000
; | RAM(R/W:初期データ)、ROM(R:追加データ)、SCC/SCC+(W:追加データ)
;BFFF
;C000
; | RAM(読み取り/書き込み)
;FFFF
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
;BFFF
;C000
; | RAM(読み取り/書き込み)
;FFFF
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

