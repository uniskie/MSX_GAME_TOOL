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
	db	0x02, 0	;S 08c00 #00 [F] 01. �T���X�̖ŖS
	db	0x04, 0	;S 08e00 #01 [P] 01. �T���X�̖ŖS
	db	0x0A, 0	;S 09200 #02 [F] 02. ���[�����[�X�̃e�[�}
	db	0x08, 0	;S 09C00 #03 [P] 02. ���[�����[�X�̃e�[�}

;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC
	db	0x02, 0	;A 3b800 #04 [F] 03. ������
	db	0x02, 0	;A 3ba00 #05 [P] 03. ������
	db	0x04, 0	;A 3bc00 #06 [F] 14. ����ł��܂���
	db	0x04, 0	;A 3c000 #07 [P] 14. ����ł��܂���
	db	0x08, 0	;A 3c400 #08 [F] 06. �E�F�C�f�j�b�c����
	db	0x06, 0	;A 3cc00 #09 [P] 06. �E�F�C�f�j�b�c����
	db	0x04, 0	;A 3d200 #10 [F] 12. ���������Ȃ�
	db	0x04, 0	;A 3d600 #11 [P] 12. ���������Ȃ�
	db	0x06, 0	;A 3da00 #12 [F] 11. �F��
	db	0x04, 0	;A 3e000 #13 [P] 11. �F��
	db	0x06, 0	;A 3e400 #14 [F] 13. 5������̒j�̂��߂�
	db	0x04, 0	;A 3ea00 #15 [P] 13. 5������̒j�̂��߂�
	db	0x06, 0	;A 3ee00 #16 [F] 17. URE-P
	db	0x06, 0	;A 3f400 #17 [P] 17. URE-P
	db	0x04, 0	;A 3fa00 #18 [F] 15. KANA-P
	db	0x02, 0	;A 3fe00 #19 [P] 15. KANA-P
	db	0x02, 1	;A 40000 #20 [F] 36. * GAME OVER
	db	0x02, 1	;A 40200 #21 [P] 36. * GAME OVER
	db	0x02, 0	;A 40400 #22 [F] 16. ������ KANA-P
	db	0x02, 0	;A 40600 #23 [P] 16. ������ KANA-P
	db	0x04, 0	;A 40800 #24 [F] 19. �����΁I
	db	0x04, 0	;A 40c00 #25 [P] 19. �����΁I
	db	0x04, 0	;A 41000 #26 [F] 20. �_�X�̃K�~�K�~
	db	0x04, 0	;A 41400 #27 [P] 20. �_�X�̃K�~�K�~
	db	0x04, 0	;A 41800 #28 [F] 32. ����Ȃ��킢
	db	0x04, 0	;A 41c00 #29 [P] 32. ����Ȃ��킢
	db	0x02, 0	;A 42000 #30 [F] 38. * �t�@���t�@�[��(�I���ۂ����������̂Ń��[�v�������������S)
	db	0x02, 1	;A 42200 #31 [P] 38. * �t�@���t�@�[��
	db	0x02, 1	;A 42400 #32 [F] 39. * ���J���g�̒G��
	db	0x02, 1	;A 42600 #33 [P] 39. * ���J���g�̒G��

;+00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2
	db	0x01, 0	;A 00400 #34 [F] 37. * �󔠃Q�b�g(�I���ۂ����������̂Ń��[�v�������������S)
	db	0x01, 0	;A 00500 #35 [F] 21. �댯���A�u�i�C
	db	0x01, 1	;A 00600 #36 [P] 37. * �󔠃Q�b�g
	db	0x01, 0	;A 00700 #37 [P] 21. �댯���A�u�i�C

;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC
	db	0x08, 0	;A 55a00 #38 [F] 04. �U�m�o��
	db	0x06, 0	;A 56200 #39 [P] 04. �U�m�o��
	db	0x06, 0	;A 56800 #40 [F] 05. �_���T�C�A����
	db	0x04, 0	;A 56e00 #41 [P] 05. �_���T�C�A����
	db	0x02, 0	;A 57200 #42 [F] 08. �V���^�p�[�T�A�M
	db	0x02, 0	;A 57400 #43 [P] 08. �V���^�p�[�T�A�M
	db	0x04, 0	;A 57600 #44 [F] 18. �~�����̓I�E�g�E�i
	db	0x04, 0	;A 57a00 #45 [P] 18. �~�����̓I�E�g�E�i
	db	0x04, 0	;A 57e00 #46 [F] 10. ���[����
	db	0x02, 0	;A 58200 #47 [P] 10. ���[����
	db	0x04, 0	;A 58400 #48 [F] 26. �T�[�^���X�̓���
	db	0x04, 0	;A 58800 #49 [P] 26. �T�[�^���X�̓���
	db	0x04, 0	;A 58c00 #50 [F] 27. ���@�s�s
	db	0x04, 0	;A 59000 #51 [P] 27. ���@�s�s
	db	0x04, 0	;A 59400 #52 [F] 28. ���}�X�J�G���R��
	db	0x04, 0	;A 59800 #53 [P] 28. ���}�X�J�G���R��

;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC
	db	0x04, 0	;B 4ca00 #54 [F] 07. �o�n�}�[���_��
	db	0x04, 0	;B 4ce00 #55 [P] 07. �o�n�}�[���_��
	db	0x02, 0	;B 4d200 #56 [F] 09. �E�F�[�f���R��
	db	0x02, 0	;B 4d400 #57 [P] 09. �E�F�[�f���R��
	db	0x04, 0	;B 4d600 #58 [F] 22. �i�v���y
	db	0x04, 0	;B 4da00 #59 [P] 22. �i�v���y
	db	0x04, 0	;B 4de00 #60 [F] 23. �I�[���}���̖�]
	db	0x04, 0	;B 4e200 #61 [P] 23. �I�[���}���̖�]
	db	0x06, 0	;B 4e600 #62 [F] 24. ��ɂ̖����m
	db	0x04, 0	;B 4ec00 #63 [P] 24. ��ɂ̖����m
	db	0x04, 0	;B 4f000 #64 [F] 25. ���₩���̓�
	db	0x04, 0	;B 4f400 #65 [P] 25. ���₩���̓�
	db	0x04, 0	;B 4f800 #66 [F] 29. �G���[�X�̗�
	db	0x04, 0	;B 4fc00 #67 [P] 29. �G���[�X�̗�
	db	0x06, 0	;B 50000 #68 [F] 30. �ÎE���p�c���B�[�t�H
	db	0x04, 0	;B 50600 #69 [P] 30. �ÎE���p�c���B�[�t�H
	db	0x06, 0	;B 50a00 #70 [F] 31. �Í�����̒E�o
	db	0x06, 0	;B 51000 #71 [P] 31. �Í�����̒E�o
	db	0x06, 0	;B 51600 #72 [F] 33. �א_����
	db	0x04, 0	;B 51c00 #73 [P] 33. �א_����

;+22000-23800 (01800 bytes) START DISK ENDING MUSIC
	db	0x08, 0	;S 22000 #74 [F] 34. �₷�炬
	db	0x06, 0	;S 22800 #75 [P] 34. �₷�炬
	db	0x06, 0	;S 22E00 #76 [F] 35. �������ӂ�Ԃ�
	db	0x04, 0	;S 23400 #77 [P] 35. �������ӂ�Ԃ�

	db	0x80

TERM:



;0000 4BYTES �}�W�b�N 'KSCC'
;0004 WORD(LE) Z80�A�h���X��Ԃ̃��[�h�A�h���X(0000-FFFF)
;0006 WORD(LE) �����f�[�^�̒����i�o�C�g�P�ʁA0000-FFFF�j
;0008 WORD(LE) Z80�A�h���X��Ԃ̏������A�h���X(0000-FFFF)
;000A WORD(LE) Z80�A�h���X��Ԃ̍Đ��A�h���X(0000-FFFF)
;000C BYTE �J�n(�I�t�Z�b�g) �o���N�ԍ�
;000D BYTE 8/16kbytes�o���N�ǉ��f�[�^�u���b�N�T�|�[�g
;                   �r�b�g0-6: 8/16k�o�C�g�̃o���N���ꂽ�ǉ��f�[�^�u���b�N�̐�
;                   �r�b�g7: �ݒ肳��Ă���ꍇ�A���̋Ȃ�KSS 8k�}�b�p�[���g�p���܂�
;000E �g���p�ɗ\�񂳂ꂽ�o�C�g�i00h�ł���K�v������܂��j
;000F BYTE �ǉ��T�E���h�`�b�v�̃T�|�[�g
;                   �r�b�g 0: �ݒ肳��Ă���ꍇ�A���̋Ȃ� FMPAC (�r�b�g 1 = 0)�AFMUNIT (�r�b�g 1 = 1) ���g�p���܂��B
;                   �r�b�g1: �ݒ肳��Ă���ꍇ�A���̋Ȃ�SN76489���g�p���܂�
;                   �r�b�g 2: �ݒ肳��Ă���ꍇ�A���̋Ȃ� RAM(�r�b�g 1=0)�AGG �X�e���I(�r�b�g 1=1) ���g�p���܂��B
;                   �r�b�g 3: �ݒ肳��Ă���ꍇ�A���̋Ȃ� MSX-AUDIO (�r�b�g 1 = 0)�ARAM (�r�b�g 1 = 1) ���g�p���܂��B
;                   �r�b�g 4-7: �\��ς݁B0 �łȂ���΂Ȃ�܂���
;0010 n BYTES �w�蒷�������f�[�^
;
;0010+n 16kBYTES �ŏ���16k�u���b�N�̒ǉ��f�[�^(�I�v�V����)
;4010+n 16kBYTES 2�Ԗڂ�16k�u���b�N�̒ǉ��f�[�^(�I�v�V����)
;...
;
;0010+n 8kBYTES �ǉ��f�[�^�̍ŏ���8k�u���b�N(�I�v�V����)
;2010+n 8kBYTES 2�Ԗڂ�8k�u���b�N�̒ǉ��f�[�^(�I�v�V����)
;
;...
;
;[KSS 16k �}�b�p�[ ������ �}�b�v]
;
;0000
; | RAM(�ǂݎ��/��������)
;7FFF
;8000
; | 16k �o���N ROM(R)�ASCC/SCC+ ������ �}�b�v I/O(W:9800-988F�AB800-B8AF)
;BFFF
;C000
; | RAM(�ǂݎ��/��������)
;FFFF
;
;[KSS 16k �}�b�p�[ RAM ���[�h ������ �}�b�v]
;
;0000
; | RAM(�ǂݎ��/��������)
;7FFF
;8000
; | RAM(R/W:�����f�[�^)�AROM(R:�ǉ��f�[�^)�ASCC/SCC+(W:�ǉ��f�[�^)
;BFFF
;C000
; | RAM(�ǂݎ��/��������)
;FFFF
;
;[KSS 8k �}�b�p�[ ������ �}�b�v]
;
;0000
; | RAM(�ǂݎ��/��������)
;7FFF
;8000
; | �ŏ��� 8k �o���N ROM(R)�A�I��(W:9000)�ASCC ������ �}�b�v I/O(W:9800-988F)
;9FFF
;A000
; | 2�Ԗڂ�8k�o���NROM(R)�A�I��(W:B000)�ASCC+�������}�b�vI/O(W:B800-B8AF)
;BFFF
;C000
; | RAM(�ǂݎ��/��������)
;FFFF
;
;[KSS I/O�}�b�v]
;
;06 GG�X�e���I�|�[�g(W)
;A0 AY3-8910 �A�h���X�|�[�g(W)
;A1 AY3-8910 �f�[�^�|�[�g(W)
;A2 AY3-8910 �ǂݎ��|�[�g(R)
;7C FMPAC�A�h���X�|�[�g(W)
;7D FMPAC�f�[�^�|�[�g(W)
;7E SN76489 �|�[�g(W)
;7F SN76489 �|�[�g(W)(7E �̃~���[)
;C0 MSX-AUDIO�A�h���X�|�[�g(W)
;C1 MSX-AUDIO�f�[�^�|�[�g(W)
;F0 FMUNIT�A�h���X�|�[�g(W)
;F1 FMUNIT�f�[�^�|�[�g(W)
;FE KSS 16k�o�C�g�o���NROM�I���|�[�g(W)
;         �s���Ȓl���������܂��ƁA�����̈悪�}�b�v����܂��B
;         (�J�n�ԍ�) <= (�L���Ȓl) < (�J�n�ԍ�) + (�u���b�N��)
;
;
;[�ǂݍ��݃v���Z�X]
;
;1) ���ׂĂ� Z80 �A�h���X��� (0000h-ffffh) ���N���A���܂��B
;2) 0000h-3fffh �� RAM �� c9h('ret' �R�[�h) �Ŗ��߂܂��B
;3) 0001h����WRTPSG�R�[�h(d3h�Aa0h�Af5h�A7Bh�Ad3h�Aa1h�Af1h�Ac9h)���������݂܂��B
;4) 0093h����WRTPSG�G���g���R�[�h(c3h,01h,00h)���������݂܂��B
;5) 0009h����RDPSG�R�[�h(d3h�Aa0h�Adbh�Aa2h�Ac9h�A)���������݂܂��B
;6) 0096h����RDPSG�G���g���R�[�h(c3h,09h,00h)���������݂܂��B
;7) �f�[�^������ Z80 �A�h���X��Ԃ� init �A�h���X�Ƀ��[�h���܂��B
;
;
;[����������]
;
;1) �u���[�h�v���Z�X�v�� Z80 �A�h���X��Ԃ����������܂��B
;2) ��]�̋Ȃ̃A�L�������[�^��ݒ肵�܂��B
;3) �X�^�b�N�|�C���^�� f380h �ɏ��������܂��B
;4) init �A�h���X���Ăяo���܂��B
;
;
;�y�v���C�̗���z
;
;1) 60Hz�ōĐ��A�h���X���Ăяo���܂��B

