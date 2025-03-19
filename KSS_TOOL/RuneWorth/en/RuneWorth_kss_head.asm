;**** for Rune Worth Music Disk (MSX2) ****

;https://github.com/AILight/AILZ80ASM

KSS_BANK_IO:	equ 0xfe

data_addr:	equ 0x2000
driver_size:	equ 0x1100
driver_szb:	equ (driver_size / 0x100)
driver_base:	equ 0x0100	;driver address (Z80)

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
	add	a,(ix+0)	;add offset
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
	ld	b,(ix+0)	;bc = size
	ld	c,0
	
	call	COPY

;copy driver
	ld	a,(data_addr)
	cp	0x10
	jr	z,USE_OPLLDRV

USE_PSGDRV:
	ld	hl,driver_szb	;hl = address / 256
	ld	de,driver_base
	ld	bc,driver_size
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,driver_base
	ld	(PLAY_ADDR),hl
	call	driver_base + 0x0003

	ld	a,(ix+1)	;a = loop count / 0=infinite loop
	ld	b,0		;b = fade-in wait-time for each one volume (in 1/60 second units)
	ld	hl,data_addr
	jp	driver_base + 0x0006

USE_OPLLDRV:

	ld	hl,0x0000	;hl = address / 256
	ld	de,driver_base
	ld	bc,driver_size
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,driver_base
	ld	(PLAY_ADDR),hl
	;ld	a,0x80
	;ld	(0xfcc1),a
	ld	a,0x00
	ld	(0x0426),a
	call	driver_base + 0x0003
	ld	a,(ix+1)	;a = loop count / 0=infinite loop
	ld	b,0		;b = fade-in wait-time for each one volume (in 1/60 second units)
	ld	hl,data_addr
	jp	driver_base + 0x0006

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
	db	0x02, 0	;S 08c00 #00 [F] 01. The Downfall of Saris
	db	0x04, 0	;S 08e00 #01 [P] 01. The Downfall of Saris
	db	0x0A, 0	;S 09200 #02 [F] 02. Theme of Rune Worth
	db	0x08, 0	;S 09C00 #03 [P] 02. Theme of Rune Worth

;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC
	db	0x02, 0	;A 3b800 #04 [F] 03. Departure
	db	0x02, 0	;A 3ba00 #05 [P] 03. Departure
	db	0x04, 0	;A 3bc00 #06 [F] 14. He Died
	db	0x04, 0	;A 3c000 #07 [P] 14. He Died
	db	0x08, 0	;A 3c400 #08 [F] 06. Weidenitz Principality
	db	0x06, 0	;A 3cc00 #09 [P] 06. Weidenitz Principality
	db	0x04, 0	;A 3d200 #10 [F] 12. Wasteful
	db	0x04, 0	;A 3d600 #11 [P] 12. Wasteful
	db	0x06, 0	;A 3da00 #12 [F] 11. Prayer
	db	0x04, 0	;A 3e000 #13 [P] 11. Prayer
	db	0x06, 0	;A 3e400 #14 [F] 13. For the men in the bar
	db	0x04, 0	;A 3ea00 #15 [P] 13. For the men in the bar
	db	0x06, 0	;A 3ee00 #16 [F] 17. Happiness
	db	0x06, 0	;A 3f400 #17 [P] 17. Happiness
	db	0x04, 0	;A 3fa00 #18 [F] 15. Sadness
	db	0x02, 0	;A 3fe00 #19 [P] 15. Sadness
	db	0x02, 1	;A 40000 #20 [F] 36. (Jingle) Game Over
	db	0x02, 1	;A 40200 #21 [P] 36. (Jingle) Game Over
	db	0x02, 0	;A 40400 #22 [F] 16. More Sadness
	db	0x02, 0	;A 40600 #23 [P] 16. More Sadness
	db	0x04, 0	;A 40800 #24 [F] 19. U-Ro-Wa-Ba!
	db	0x04, 0	;A 40c00 #25 [P] 19. U-Ro-Wa-Ba!
	db	0x04, 0	;A 41000 #26 [F] 20. Griping of the Gods
	db	0x04, 0	;A 41400 #27 [P] 20. Griping of the Gods
	db	0x04, 0	;A 41800 #28 [F] 32. The never ending battle
	db	0x04, 0	;A 41c00 #29 [P] 32. The never ending battle
	db	0x02, 0	;A 42000 #30 [F] 38. (Jingle) Fanfare(Loop it. The sound will remain at the end, so)
	db	0x02, 1	;A 42200 #31 [P] 38. (Jingle) Fanfare
	db	0x02, 1	;A 42400 #32 [F] 39. (Jingle) Ricart's Lyre
	db	0x02, 1	;A 42600 #33 [P] 39. (Jingle) Ricart's Lyre

;+00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2
	db	0x01, 0	;A 00400 #34 [F] 37. (Jingle) Get Treasure(Loop it. The sound will remain at the end, so)
	db	0x01, 0	;A 00500 #35 [F] 21. Look out, it's Dangerous
	db	0x01, 1	;A 00600 #36 [P] 37. (Jingle) Get Treasure
	db	0x01, 0	;A 00700 #37 [P] 21. Look out, it's Dangerous

;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC
	db	0x08, 0	;A 55a00 #38 [F] 04. Zamba Fortress
	db	0x06, 0	;A 56200 #39 [P] 04. Zamba Fortress
	db	0x06, 0	;A 56800 #40 [F] 05. Holy Saia Kingdom
	db	0x04, 0	;A 56e00 #41 [P] 05. Holy Saia Kingdom
	db	0x02, 0	;A 57200 #42 [F] 08. Shatapartha Commonwealth
	db	0x02, 0	;A 57400 #43 [P] 08. Shatapartha Commonwealth
	db	0x04, 0	;A 57600 #44 [F] 18. Mirim is a Grown-up
	db	0x04, 0	;A 57a00 #45 [P] 18. Mirim is a Grown-up
	db	0x04, 0	;A 57e00 #46 [F] 10. His Majesty
	db	0x02, 0	;A 58200 #47 [P] 10. His Majesty
	db	0x04, 0	;A 58400 #48 [F] 26. Revelation of Sartarus
	db	0x04, 0	;A 58800 #49 [P] 26. Revelation of Sartarus
	db	0x04, 0	;A 58c00 #50 [F] 27. Outrageous Town
	db	0x04, 0	;A 59000 #51 [P] 27. Outrageous Town
	db	0x04, 0	;A 59400 #52 [F] 28. Lumaskaeru Burns
	db	0x04, 0	;A 59800 #53 [P] 28. Lumaskaeru Burns

;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC
	db	0x04, 0	;B 4ca00 #54 [F] 07. Bahaman Divine Kingddom
	db	0x04, 0	;B 4ce00 #55 [P] 07. Bahaman Divine Kingddom
	db	0x02, 0	;B 4d200 #56 [F] 09. Wedel Mountains
	db	0x02, 0	;B 4d400 #57 [P] 09. Wedel Mountains
	db	0x04, 0	;B 4d600 #58 [F] 22. Permafrost
	db	0x04, 0	;B 4da00 #59 [P] 22. Permafrost
	db	0x04, 0	;B 4de00 #60 [F] 23. Oorumamu's Ambition
	db	0x04, 0	;B 4e200 #61 [P] 23. Oorumamu's Ambition
	db	0x06, 0	;B 4e600 #62 [F] 24. The Dread Wizard
	db	0x04, 0	;B 4ec00 #63 [P] 24. The Dread Wizard
	db	0x04, 0	;B 4f000 #64 [F] 25. Specter's Tower
	db	0x04, 0	;B 4f400 #65 [P] 25. Specter's Tower
	db	0x04, 0	;B 4f800 #66 [F] 29. Tear of Eris
	db	0x04, 0	;B 4fc00 #67 [P] 29. Tear of Eris
	db	0x06, 0	;B 50000 #68 [F] 30. Assassin Magic Troupe Vifo
	db	0x04, 0	;B 50600 #69 [P] 30. Assassin Magic Troupe Vifo
	db	0x06, 0	;B 50a00 #70 [F] 31. Escape from the Darkness
	db	0x06, 0	;B 51000 #71 [P] 31. Escape from the Darkness
	db	0x06, 0	;B 51600 #72 [F] 33. Revival of the Evil God
	db	0x04, 0	;B 51c00 #73 [P] 33. Revival of the Evil God

;+22000-23800 (01800 bytes) START DISK ENDING MUSIC
	db	0x08, 0	;S 22000 #74 [F] 34. Peaceful
	db	0x06, 0	;S 22800 #75 [P] 34. Peaceful
	db	0x06, 0	;S 22E00 #76 [F] 35. Tomorrow will Come Back
	db	0x04, 0	;S 23400 #77 [P] 35. Tomorrow will Come Back

	db	0x80

TERM:



;KSS Music Format Spec
;
;
;V1.03 - Nov. 26, 2000 Added MSX-AUDIO mode
;V1.02 - Oct. 5, 2000  Added RAM mode
;V1.01 - Aug. 8, 2000  Added KSS 8k mapper
;V1.00 - Jul. 22, 2000 First unofficial KSS specification file
;
;
;By: Mamiya mamiya@proc.org.tohoku.ac.jp
;
;
;[FILE FORMAT]
;
;0000    4BYTES    magic 'KSCC'
;0004    WORD(LE)  load address of Z80 address space (0000-FFFF)
;0006    WORD(LE)  length of initial data in byte (0000-FFFF)
;0008    WORD(LE)  init address of Z80 address space (0000-FFFF)
;000A    WORD(LE)  play address of Z80 address space (0000-FFFF)
;000C    BYTE      start(offset) no of bank
;000D    BYTE      8/16kbytes banked extra data blocks support
;                   bits 0-6: number of 8/16kbytes banked extra data blocks
;                   bit 7: if set, this song uses KSS 8k mapper
;000E    BYTE      reserved for expansion (must be 00h)
;000F    BYTE      extra sound chip support
;                   bit 0: if set, this song uses FMPAC(bit 1=0),FMUNIT(bit 1=1)
;                   bit 1: if set, this song uses SN76489
;                   bit 2: if set, this song uses RAM(bit 1=0),GG stereo(bit 1=1)
;                   bit 3: if set, this song uses MSX-AUDIO(bit 1=0),RAM(bit 1=1)
;                   bits 4-7: reserved. they *must* be 0
;0010    n BYTES   specified length initial data
;
;0010+n  16kBYTES  1st 16k block of extra data(option)
;4010+n  16kBYTES  2nd 16k block of extra data(option)
;...
;
;0010+n  8kBYTES   1st 8k block of extra data(option)
;2010+n  8kBYTES   2nd 8k block of extra data(option)
;...
;
;[KSS 16k mapper memory map]
;
;0000
; |      RAM(R/W)
;7FFF
;8000
; |      16k banked ROM(R), SCC/SCC+ memory mapped I/O(W:9800-988F,B800-B8AF)
;BFFF
;C000
; |      RAM(R/W)
;FFFF
;
;[KSS 16k mapper RAM mode memory map]
;
;0000
; |      RAM(R/W)
;7FFF
;8000
; |      RAM(R/W:initial data),ROM(R:extra data),SCC/SCC+(W:extra data)
;BFFF
;C000
; |      RAM(R/W)
;FFFF
;
;[KSS 8k mapper memory map]
;
;0000
; |      RAM(R/W)
;7FFF
;8000
; |      1st 8k banked ROM(R),select(W:9000),SCC memory mapped I/O(W:9800-988F)
;9FFF
;A000
; |      2nd 8k banked ROM(R),select(W:B000),SCC+ memory mapped I/O(W:B800-B8AF)
;BFFF
;C000
; |      RAM(R/W)
;FFFF
;
;[KSS I/O map]
;
;06      GG stereo port(W)
;A0      AY3-8910 address port(W)
;A1      AY3-8910 data port(W)
;A2      AY3-8910 read port(R)
;7C      FMPAC address port(W)
;7D      FMPAC data port(W)
;7E      SN76489 port(W)
;7F      SN76489 port(W)(mirror of 7E)
;C0      MSX-AUDIO address port(W)
;C1      MSX-AUDIO data port(W)
;F0      FMUNIT address port(W)
;F1      FMUNIT data port(W)
;FE      KSS 16kbytes-banked ROM select port(W)
;         Initial area will be mapped, when ilegal value is writed.
;         (start no) <= (legal value) < (start no) + (number of blocks)
;
;
;[Loading process]
;
;1) Clear all Z80 address space(0000h-ffffh).
;2) Fill RAM at 0000h-3fffh with c9h('ret' code).
;3) Write WRTPSG codes(d3h,a0h,f5h,7Bh,d3h,a1h,f1h,c9h) from 0001h.
;4) Write WRTPSG entry codes(c3h,01h,00h) from 0093h.
;5) Write RDPSG codes(d3h,a0h,dbh,a2h,c9h,) from 0009h.
;6) Write RDPSG entry codes(c3h,09h,00h) from 0096h.
;7) Load the data into the init address of initial Z80 address space.
;
;
;[Initializing process]
;
;1) Initialize Z80 address space on 'loading process'.
;2) Set the accumulator for the desired song.
;3) Initialize stack pointer to f380h.
;4) Call the init address.
;
;
;[Playing process]
;
;1) Call the play address at 60Hz.
;