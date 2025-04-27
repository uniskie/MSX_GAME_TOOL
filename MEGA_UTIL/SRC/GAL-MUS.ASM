;***************************
; Maze of GALIOUS SOUND-BOX
; FOR KANJI
;***************************
; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

;--------------------------------------
USE_KEYBUFFER: EQU	1	;ENABLE KEY BUFFER in EX-BIOOS
;--------------------------------------

ORGADR:	EQU	0C000H

; A=USR(0)
;	FNAME	"GAL-MUS.BIN"	;*BINHEAD*
	ORG	ORGADR-7
	DB	0FEH	;*BINHEAD*
	DW	ORGADR	;*BINHEAD*
	DW	ENDFL-1	;*BINHEAD*
	DW	ORGADR ;*BINHEAD*;

;--------------------------------------
;BIOS LABELS for GAME UTILS
	INCLUDE "BIOS-DEF.ASM"

;--------------------------------------

	ORG	ORGADR

ORGFL:
	JP	JUKEBOX_

;--------------------------------------
PLAYWK:	;BGM,SE,LINE(BGM,SE,EXIT)
	DB	87H,01H,1
SVW_SP:	DW	0

;WAITCT:	DB	0	;WAIT CNT
;--------------------------------------
SV_HOOK:
	DBFIL	5

;--------------------------------------
JUKEBOX_:
	DI
;	IM	1
	LD	(SVW_SP),SP
	LD	SP,0D300H

	LD	HL,H_KEYI
	LD	DE,SV_HOOK
	LD	BC,5
	LDIR

	LD	A,4
	LD	C,40H
	LD	HL,8000H
	LD	B,40H
	CALL	TF_VRM	;COMMON
	LD	A,6
	LD	C,40H+20H
	LD	HL,0E000H
	LD	B,1FH
	CALL	TF_VRM	;COMMON

	LD	A,(RAMAD0+1)
	LD	H,40H
	CALL	ENASLT

	LD	A,5
	LD	C,0
	LD	HL,4000H
	LD	B,60H
	CALL	TF_RAM	;COMMON

	LD	HL,PLAY_TRAP
	LD	(H_KEYI+1),HL
	LD	A,0C3H
	LD	(H_KEYI),A

	CALL	PLAY

;--------------------------------------
RET_BAS:
	LD	A,4
	LD	C,0
	LD	HL,8000H
	LD	B,40H
	CALL	TF_RAM	;COMMON
	LD	A,6
	LD	C,20H
	LD	HL,0E000H
	LD	B,1FH
	CALL	TF_RAM	;COMMON

	LD	A,(EXPTBL)
	LD	H,40H
	CALL	ENASLT

	LD	HL,SV_HOOK
	LD	DE,H_KEYI
	LD	BC,5
	LDIR

	LD	SP,(SVW_SP)
;	IM	0
	EI

	RET

;--------------------------------------
PLAY:	LD	HL,0E000H
	LD	DE,0E001H
	LD	BC,010EFH
	LD	(HL),0
	LDIR

	LD	A,87H	;DEFAULT BGM No.
	LD	(MUS_NO),A	;CURRENT BGM

	JP	PLAY_SUB

;--------------------------------------
PLAY_R:	DI
	LD	A,7
	OUT	(PSGIO),A
	LD	A,0BFH
	OUT	(PSGIO+1),A

.@1:	LD	DE,0801H	;'SPC'
	CALL	KEYIN	;D=KEYMTX NO / E=MASK
	JP	Z,.@1
	RET

;--------------------------------------
PLAY_TRAP:	EQU	PLAY_TR

;--------------------------------------
	INCLUDE	"GAL-PLKD.ASM"
	INCLUDE "GAL-PLAY.ASM"
	INCLUDE	"EX-BIOS.ASM"
	INCLUDE	"KJ-VDP.ASM"
	INCLUDE	"GAL-TL-K.ASM"

ENDFL:
