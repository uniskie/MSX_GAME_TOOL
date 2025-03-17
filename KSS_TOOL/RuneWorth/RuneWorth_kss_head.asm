;**** for Rune Worth Music Disk (MSX2) ****

;https://github.com/AILight/AILZ80ASM

KSS_BANK_IO:   equ 0xfe

data_addr:  equ 0x2000

BASE: equ 0x7000

	org	BASE-0x10

	db	'KSCC'		; +0: �}�W�b�N�R�[�h
	dw	LOAD		; +4: ���[�h�A�h���X    �iZ80�A�h���X��ԁj
	dw	TERM-BASE	; +6: �����f�[�^�̒���
	dw	INIT		; +8: �����������A�h���X�iZ80�A�h���X��ԁj
	dw	PLAY		; +a: �Đ������A�h���X  �iZ80�A�h���X��ԁj
	db	0x00		; +c: �J�n�o���N�ԍ�
	db	6		; +d: b7=0:16k bank / 6 block
	db	0x00		; +e: (reserve)
	db	0x05		; +f: 00001001
				;         xx: ------01 = FMPAC���g��
				;       x  x: ----1-0- = MSX-AUDIO���g��

LOAD:
	ret

PLAY:
	db	0xc3
PLAY_ADDR:
	dw	LOAD

INIT:
	ld	ix,TABLE
	ld	h,0x00
	ld	l,0x1e+0x1e	;driver size(opll+psg) / 256
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
	ld	hl,0x001e	;hl = address / 256
	ld	de,0x0100
	ld	bc,0x1e00
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,0x0100
	ld	(PLAY_ADDR),hl
	call	0x0103

	ld	a,(ix+1)	;a = loop count / 0=infinite loop
	ld	b,0		;b = fade-in wait-time for each one volume (in 1/60 second units)
	ld	hl,0x2000
	jp	0x0106

USE_OPLLDRV:

	ld	hl,0x0000	;hl = address / 256
	ld	de,0x0100
	ld	bc,0x1e00
	call	COPY
	;remap ram
	ld	a,0x7f
	out	(KSS_BANK_IO),a
	ld	hl,0x020c
	ld	(PLAY_ADDR),hl
	;ld	a,0x80
	;ld	(0xfcc1),a
	ld	a,0x00
	ld	(0x0426),a
	call	0x0200
	ld	a,(ix+1)	;a = loop count / 0=infinite loop
	ld	b,0		;b = fade-in wait-time for each one volume (in 1/60 second units)
	ld	hl,0x2000
	jp	0x0106

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
;psgdrv4 (RAM:0100-1EFF)  +7EBD size:1E00
;oplldrv4 (RAM:0100-1EFF) +6E00 size:1E00

;+08c00-0a400 (01800 bytes) START DISK OPENING MUSIC
	db	0x02, 0	;S 08c00 #00 (00) [F] 01. �T���X�̖ŖS
	db	0x04, 0	;S 08e00 #01 (01) [P] 01. �T���X�̖ŖS
	db	0x0A, 0	;S 09200 #02 (02) [F] 02. ���[�����[�X�̃e�[�}
	db	0x08, 0	;S 09C00 #03 (03) [P] 02. ���[�����[�X�̃e�[�}

;+3B800-42800 (07000 bytes) GAME DISK A/B COMMON MUSIC
	db	0x02, 0	;A 3b800 #04 (04) [F] 03. ������
	db	0x02, 0	;A 3ba00 #05 (05) [P] 03. ������
	db	0x04, 0	;A 3bc00 #06 (06) [F] 14. ����ł��܂���
	db	0x04, 0	;A 3c000 #07 (07) [P] 14. ����ł��܂���
	db	0x08, 0	;A 3c400 #08 (08) [F] 06. �E�F�C�f�j�b�c����
	db	0x06, 0	;A 3cc00 #09 (09) [P] 06. �E�F�C�f�j�b�c����
	db	0x04, 0	;A 3d200 #0A (10) [F] 12. ���������Ȃ�
	db	0x04, 0	;A 3d600 #0B (11) [P] 12. ���������Ȃ�
	db	0x06, 0	;A 3da00 #0C (12) [F] 11. �F��
	db	0x04, 0	;A 3e000 #0D (13) [P] 11. �F��
	db	0x06, 0	;A 3e400 #0E (14) [F] 13. 5������̒j�̂��߂�
	db	0x04, 0	;A 3ea00 #0F (15) [P] 13. 5������̒j�̂��߂�
	db	0x06, 0	;A 3ee00 #10 (16) [F] 17. URE-P
	db	0x06, 0	;A 3f400 #11 (17) [P] 17. URE-P
	db	0x04, 0	;A 3fa00 #12 (18) [F] 15. KANA-P
	db	0x02, 0	;A 3fe00 #13 (19) [P] 15. KANA-P
	db	0x02, 1	;A 40000 #14 (20) [F] 36. * GAME OVER
	db	0x02, 1	;A 40200 #15 (21) [P] 36. * GAME OVER
	db	0x02, 0	;A 40400 #16 (22) [F] 16. ������ KANA-P
	db	0x02, 0	;A 40600 #17 (23) [P] 16. ������ KANA-P
	db	0x04, 0	;A 40800 #18 (24) [F] 19. �����΁I
	db	0x04, 0	;A 40c00 #19 (25) [P] 19. �����΁I
	db	0x04, 0	;A 41000 #1A (26) [F] 20. �_�X�̃K�~�K�~
	db	0x04, 0	;A 41400 #1B (27) [P] 20. �_�X�̃K�~�K�~
	db	0x04, 0	;A 41800 #1C (28) [F] 32. ����Ȃ��킢
	db	0x04, 0	;A 41c00 #1D (29) [P] 32. ����Ȃ��킢
	db	0x02, 0	;A 42000 #1E (30) [F] 38. * �t�@���t�@�[��(�I���ۂ����������̂Ń��[�v�������������S)
	db	0x02, 1	;A 42200 #1F (31) [P] 38. * �t�@���t�@�[��
	db	0x02, 1	;A 42400 #20 (32) [F] 39. * ���J���g�̒G��
	db	0x02, 1	;A 42600 #21 (33) [P] 39. * ���J���g�̒G��

;+00200-00500 (00300 bytes) GAME DISK A/B COMMON MUSIC 2
	db	0x01, 0	;A 00400 #22 (34) [F] 37. * �󔠃Q�b�g(�I���ۂ����������̂Ń��[�v�������������S)
	db	0x01, 0	;A 00500 #23 (35) [F] 21. �댯���A�u�i�C
	db	0x01, 1	;A 00600 #24 (36) [P] 37. * �󔠃Q�b�g
	db	0x01, 0	;A 00700 #25 (37) [P] 21. �댯���A�u�i�C

;+55A00-5A000 (04600 bytes) GAME DISK A MUSIC
	db	0x08, 0	;A 55a00 #26 (38) [F] 04. �U�m�o��
	db	0x06, 0	;A 56200 #27 (39) [P] 04. �U�m�o��
	db	0x06, 0	;A 56800 #28 (40) [F] 05. �_���T�C�A����
	db	0x04, 0	;A 56e00 #29 (41) [P] 05. �_���T�C�A����
	db	0x02, 0	;A 57200 #2A (42) [F] 08. �V���^�p�[�T�A�M
	db	0x02, 0	;A 57400 #2B (43) [P] 08. �V���^�p�[�T�A�M
	db	0x04, 0	;A 57600 #2C (44) [F] 18. �~�����̓I�E�g�E�i
	db	0x04, 0	;A 57a00 #2D (45) [P] 18. �~�����̓I�E�g�E�i
	db	0x04, 0	;A 57e00 #2E (46) [F] 10. ���[����
	db	0x02, 0	;A 58200 #2F (47) [P] 10. ���[����
	db	0x04, 0	;A 58400 #30 (48) [F] 26. �T�[�^���X�̓���
	db	0x04, 0	;A 58800 #31 (49) [P] 26. �T�[�^���X�̓���
	db	0x04, 0	;A 58c00 #32 (50) [F] 27. ���@�s�s
	db	0x04, 0	;A 59000 #33 (51) [P] 27. ���@�s�s
	db	0x04, 0	;A 59400 #34 (52) [F] 28. ���}�X�J�G���R��
	db	0x04, 0	;A 59800 #35 (53) [P] 28. ���}�X�J�G���R��

;+4CA00-52000 (05600 bytes) GAME DISK B MUSIC
	db	0x04, 0	;B 4ca00 #36 (54) [F] 07. �o�n�}�[���_��
	db	0x04, 0	;B 4ce00 #37 (55) [P] 07. �o�n�}�[���_��
	db	0x02, 0	;B 4d200 #38 (56) [F] 09. �E�F�[�f���R��
	db	0x02, 0	;B 4d400 #39 (57) [P] 09. �E�F�[�f���R��
	db	0x04, 0	;B 4d600 #3A (58) [F] 22. �i�v���y
	db	0x04, 0	;B 4da00 #3B (59) [P] 22. �i�v���y
	db	0x04, 0	;B 4de00 #3C (60) [F] 23. �I�[���}���̖�]
	db	0x04, 0	;B 4e200 #3D (61) [P] 23. �I�[���}���̖�]
	db	0x06, 0	;B 4e600 #3E (62) [F] 24. ��ɂ̖����m
	db	0x04, 0	;B 4ec00 #3F (63) [P] 24. ��ɂ̖����m
	db	0x04, 0	;B 4f000 #40 (64) [F] 25. ���₩���̓�
	db	0x04, 0	;B 4f400 #41 (65) [P] 25. ���₩���̓�
	db	0x04, 0	;B 4f800 #42 (66) [F] 29. �G���[�X�̗�
	db	0x04, 0	;B 4fc00 #43 (67) [P] 29. �G���[�X�̗�
	db	0x06, 0	;B 50000 #44 (68) [F] 30. �ÎE���p�c���B�[�t�H
	db	0x04, 0	;B 50600 #45 (69) [P] 30. �ÎE���p�c���B�[�t�H
	db	0x06, 0	;B 50a00 #46 (70) [F] 31. �Í�����̒E�o
	db	0x06, 0	;B 51000 #47 (71) [P] 31. �Í�����̒E�o
	db	0x06, 0	;B 51600 #48 (72) [F] 33. �א_����
	db	0x04, 0	;B 51c00 #49 (73) [P] 33. �א_����

;+22000-23800 (01800 bytes) START DISK ENDING MUSIC
	db	0x08,0	;S 22000 #4A (74) [F] 34. �₷�炬
	db	0x06,0	;S 22800 #4B (75) [P] 34. �₷�炬
	db	0x06,0	;S 22E00 #4C (76) [F] 35. �������ӂ�Ԃ�
	db	0x04,0	;S 23400 #4D (77) [P] 35. �������ӂ�Ԃ�

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

