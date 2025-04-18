;***************************
;   SET TRAP for  F1SPIRIT
;***************************
; for tniasm v0.45
; http://www.tni.nl/products/tniasm.html

; A=USR( TIME-TRAP � ���ڽ )

;--------------------------------------
	FNAME	"F1SPIRIT.BIN"	;*BINHEAD*
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
;--------------------------------------

;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------
; F1SPIRIT ROM ENTRY
;--------------------------------------
F1SP_ADR:	EQU	4117H
TRAP_MS:	EQU	4018H	;F1SPIRIT H.KEYI
MAGICN:	EQU	40E4H	;GAME ROM CHEK ID
GAMESPA:	EQU	0F0F0H

; KONAMI MEGA-ROM BANK
;W_BANK:	EQU	0F0F1H
;BANK1:	EQU	7000H
;BANK2:	EQU	9000H
;BANK3:	EQU	0B000H

;--------------------------------------
; ENTRY (EXPORT)
;--------------------------------------
ORGADR:	EQU	0C000H
	ORG	ORGADR

	JP	F1SPIRIT_
	JP	ROM_CHK	;KONAMI8K.ASM
;--------------------------------------
; WORK AREA (EXPORT)
;--------------------------------------
F1SP_REF:
	DB	0
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	33H,01H,0
;ROMSLT:	DB	1
;CPUSAV:	DB	0

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
W_SLREG:
	DB	0
SV_HOOK:
	DS	5
SVPHOOK:
	DS	5

;--------------------------------------
;GAME:
;	VRAM: 16KByte
;	RAM : 8KByte ($e000-$fc00)
;--------------------------------------

;--------------------------------------
;VRAM SAVE Version:(Current Version)
; * MSX1: not work
; * VRAM SAVE: easy in BASIC
; * Save Slot: 2

;$4000	AUTO STATE RAM 8KByte
;	AUTO STATE VRAM 16KByte
;$8000	STATE RAM 8KByte
;	STATE VRAM 16KByte
;$10000	BASIC RAM 8KByte
;	BASIC VRAM 16KByte
;--------------------------------------
;RAM SAVE Version:(Scrapped Plan)
; * MSX1: work
; * VRAM SAVE: Difficult in BASIC.
; * Save Slot: 1

;$0000	BASIC RAM 8KByte
;$2000	STATE RAM 8KByte
;$4000	STATE VRAM 16KByte
;--------------------------------------

;--------------------------------------
; ROUTINES
;--------------------------------------
F1SPIRIT_:
	; FROM BASIC
	CALL CPUZ80
	DI
	LD	(SVW_SP),SP
	CALL	RSLREG
	LD	(W_SLREG),A
	LD	A,V_PG3	;COMMON
	CALL	SAVE_	;COMMON

	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR

	; INIIALIZE GAME
;	IM	1
	LD	SP,GAMESPA

	LD	A,(ROMSLT)
	LD	H,40H
	CALL	ENASLT
	LD	A,(ROMSLT)
	LD	H,80H
	CALL	ENASLT

	XOR	A
	LD	(CLIKSW),A

	LD	A,1
	CALL	CHGCAP	;COMMON

	LD	HL,EX_TRAP	;COMMON
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A

	LD	A,(F1SP_REF)
	DEC	A
	JP	Z,LOAD	;COMMON
	INC	A
	JP	NZ,LOAD_AT	;COMMON

	JP	F1SP_ADR

;4002  dw     #40E4        E4 40

;F1SP_BOOT
;40E4  di                  F3
;40E5  call   RSLREG       CD 38 01
;40E8  rrca                0F
;40E9  rrca                0F
;40EA  and    #03          E6 03
;40EC  ld     c,a          4F
;40ED  ld     b,#00        06 00
;40EF  ld     hl,EXPTBL    21 C1 FC
;40F2  add    hl,bc        09
;40F3  ld     a,(hl)       7E
;40F4  and    #80          E6 80
;40F6  or     c            B1
;40F7  ld     c,a          4F
;40F8  inc    hl           23
;40F9  inc    hl           23
;40FA  inc    hl           23
;40FB  inc    hl           23
;40FC  ld     a,(hl)       7E
;40FD  and    #0c          E6 0C
;40FF  or     c            B1
;4100  ld     h,#80        26 80
;4102  call   ENASLT;#0024        CD 24 00
;4105  xor    a            AF
;4106  ld     (CLIKSW),A	;(#f3db),a    32 DB F3
;4109  ld     a,#c3        3E C3
;410B  ld     (H_KEYI),A	;(#fd9a),a    32 9A FD
;410E  ld     hl,#4018     21 18 40
;4111  ld     (H_KEYI+1),HL	;(#fd9b),hl   22 9B FD
;4114  ld     sp,#f0f0     31 F0 F0

;F1SP_ADR:
;4117:  LD     HL,CH_WORK1    	;21 00 E0
;411A:  LD     DE,#E001       	;11 01 E0
;411D:  LD     BC,#10FF       	;01 FF 10
;4120:  LD     (HL),#00       	;36 00
;4122:  LDIR                  	;ED B0
;4124:  LD     A,#01          	;3E 01
;4126:  LD     (#E1C5),A      	;32 C5 E1
;4129:  CALL   #42B9         	;CD B9 42
;412C:  CALL   RDVDP          	;CD 3E 01
;412F:  XOR    A              	;AF
;4130:  LD     (#E1C5),A      	;32 C5 E1
;4133:  DI                    	;F3
;....

;--------------------------------------
RET_BAS:
	LD	A,(W_SLREG)
	CALL	WSLREG

	LD	HL,SV_HOOK
	LD	DE,H_KEYI
	LD	BC,5
	LDIR
	LD	SP,(SVW_SP)	;COMMON
;	IM	0
	EI

	CALL	CPURES
	RET

;--------------------------------------
PLAY:	LD	HL,H_KEYI
	LD	DE,SVPHOOK
	LD	BC,5
	LDIR

	DI
	LD	A,0C3H
	LD	HL,PLAY_TRAP
	LD	(H_KEYI),A
	LD	(H_KEYI+1),HL

	LD	A,V_PG1	;COMMON
	CALL	SAVE_	;COMMON

	LD	A,(RG8SAV)
	OR	2
	OUT	(VDP+1),A	;SPRITE OFF
	LD	A,8+80H
	OUT	(VDP+1),A
	XOR	A
	OUT	(VDP+1),A	;BACK COLOR=0
	LD	A,7+80H
	OUT	(VDP+1),A

	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	LD	DE,H_KEYI
	LD	HL,SVPHOOK
	LD	BC,5
	LDIR

	LD	A,V_PG1	;COMMON
	CALL	LOAD_	;COMMON


	LD	A,(RG8SAV)
	AND	253
	OUT	(VDP+1),A	;SPRITE ON
	LD	A,8+80H
	OUT	(VDP+1),A

	LD	DE,0801H	;'SPC'
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,$-6
	JP	RETURN

;--------------------------------------
PLAY_TRAP:
	LD	A,0DH
	LD	(BANK1),A
	INC	A
	LD	(BANK2),A
	INC	A
	LD	(BANK3),A
	JP	PLAY_TR

;--------------------------------------
SEL_SCC:
	LD	A,3FH
	LD	(BANK2),A
	RET

RET_SCC:
	RET

;--------------------------------------
	INCLUDE "KONAMI8K.ASM"	;*FILE*
	INCLUDE	"F1SPPLAY.ASM"	;*FILE*
	INCLUDE	"F1SP-EXP.ASM"	;*FILE*
	INCLUDE	"EX-BIOS.ASM"	;*FILE*
;--------------------------------------
; ENASLT CLONE (FOR PAGE 0 SLOT CHANGE)
	INCLUDE "CHGSLT.ASM"	;*FILE*
;--------------------------------------
ENDFL:
