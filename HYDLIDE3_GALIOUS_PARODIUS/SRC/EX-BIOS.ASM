;BIOS LABELS for GAME UTILS
;	INCLUDE "BIOS-DEF.ASM"

;DEFINE IF USE KEY BUFFER
;USE_KEYBUFFER: EQU	1

;--------------------------------------
; USE BIOS
;--------------------------------------
;KEYIO:	EQU	0A9H
;CHGCPU:	EQU	0180H
;GETCPU:	EQU	0183H

; BASIC:PLAY MML WORK
;MCLTAB:	EQU	0F956H	;2+1+24+4=31bytes
;VOICAQ:	EQU	0F975H	;128bytes
;VOICBQ:	EQU	0F9F5H	;128bytes
;VOICCQ:	EQU	0FA75H	;128bytes
;VCBA:	EQU	0FB41H	;37 bytes
;VCBB:	EQU	0FB66H	;37 bytes
;VCBC:	EQU	0FB8BH	;37 bytes
; BASIC COMMAND LINE BUFFER
;BUF:	EQU	0F55EH+1	;0F55EH,258

;VDP REG SAVE AREA
;REG0SV:	EQU	0F3DFH
;RG7SAV(F3E6H, 1), STATFL(F3E7H, 1)

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
IFDEF USE_KEYBUFFER
; KEY MATRIX BUFFER
KEYBFSZ:	EQU	11	; KEY MATRIX SIZE
KEYBMAT:	DS	KEYBFSZ	; CURRENT
KEYBTRG:	DS	KEYBFSZ	; TRIGGER
ENDIF ;USE_KEYBUFFER

;--------------------------------------
; WORK AREA (STATIC)
;--------------------------------------
CPUSAV:	DB	0	;SAVE CPU MODE

;--------------------------------------
; READ KEY MATRIX
; IN:	D = KEY MATRIX No.
;	E = BIT MASK
KEYIN:	IN	A,(KEYIO1)
	AND	0F0H
	OR	D
	OUT	(KEYIO1),A
	IN	A,(KEYIO0)
	AND	E
	RET

IFDEF USE_KEYBUFFER
;--------------------------------------
; READ KEY MATRIX BUFFER
; IN:	D = KEY MATRIX No.
;	E = BIT MASK
KEYCUR:	PUSH	HL
	LD	HL,KEYBMAT
	LD	A,D
	ADD	A,L
	LD	L,A
	LD	A,H
	ADC	A,0
	LD	H,A
	LD	A,(HL)
	AND	E
	POP	HL
	RET

;--------------------------------------
; CHECK KEY TRIGGER
; IN:	D = KEY MATRIX No.
;	E = BIT MASK
KEYTRG:	PUSH	HL
	LD	HL,KEYBTRG
	LD	A,D
	ADD	A,L
	LD	L,A
	LD	A,H
	ADC	A,0
	LD	H,A
	LD	A,(HL)
	AND	E
	POP	HL
	RET

;--------------------------------------
; UPDATE KEY MATRIX & TRIGGER BUFFER
;
; USE: AF,BC,DE,HL
KEYUPD:	LD	HL,KEYBMAT+KEYBFSZ
	LD	DE,KEYBTRG+KEYBFSZ
	LD	B,KEYBFSZ
KEYUPD_L:
	DEC	HL
	DEC	DE

	LD	A,(HL)	;A=¾ÞÝ¶² µ¼Ã²À ·°
	CPL	; BITÊÝÃÝ
	LD	C,A	;C=¾ÞÝ¶²µ¼Ã²Å²·° É Ï½¸

	;KEYIN
	IN	A,(KEYIO1)
	AND	0F0H
	OR	B
	DEC	A
	OUT	(KEYIO1),A
	IN	A,(KEYIO0)

	LD	(HL),A	;A=CURRENT:²Ï‚Ì¼Þ®³À²
	OR	C	;1=key off
	LD	(DE),A	;A=PRESS EDGE:¾ÞÝ¶² µ¼Ã²À ·° ²¶Þ² É ¼Þ®³À²

	DJNZ	KEYUPD_L
	RET
ENDIF	;USE_KEYBUFFER

;--------------------------------------
;RESTORE VDP (READ BASIC WORKAREA)
WR_CRG:	XOR	A
	OUT	(VDP+1),A
	LD	A,17+80H
	OUT	(VDP+1),A

	LD	HL,REG0SV
	LD	BC,089BH
	OTIR
	RET

;--------------------------------------
; SET VRAM R/W ADDRESS

; A:VRAM bit14-16
; C:VRAM bit 8-13 + 40H( WHEN WRITE )
; (VRAM ADDRES=A*4000H+(C AND 3FH)*100H)
VSET:	OUT	(VDP+1),A
	LD	A,14+80H
	OUT	(VDP+1),A
	XOR	A
	OUT	(VDP+1),A
	LD	A,C
	OUT	(VDP+1),A
	RET

;--------------------------------------
; TRANSFER RAM to VRAM
; (VRAM ADDRES=A*4000H+(C AND 3FH)*100H)
; IN:	HL:RAM ADDRESS
;	A:VRAM bit14-16
;	C:VRAM bit 8-13 + 40H( WHEN WRITE )
;	B:SIZE/100H
;
;TF_VRM:	 LD    C,40H
TF_VRM:
	;SET	5,C
	CALL	VSET
	LD	A,B
	LD	BC,VDP
L_FVRM:	OTIR
	DEC	A
	JP	NZ,L_FVRM
	RET

;--------------------------------------
; TRANSFER VRAM to RAM
; (VRAM ADDRES=A*4000H+(C AND 3FH)*100H)
; IN:	HL:RAM ADDRESS
;	A:VRAM bit14-16
;	C:VRAM bit 8-13 
;	B:SIZE/100H
;TF_RAM:	LD	C,0
TF_RAM:
	;RES	5,C
	CALL	VSET
	LD	A,B
	LD	BC,VDP
L_FRAM:	INIR
	DEC	A
	JP	NZ,L_FRAM
	RET

;;--------------------------------------
;IFDEF USE_VSYNC_AWIT
;;--------------------------------------
;; WAIT VSYNC (for MSX2 or upper / Not for MSX1)
;;
;; USE:AF,BC
;; RET:A 1=ok/0=wait
;; *** NEED DI !
;WTVSYNC:
;;	DI
;	LD	C,VDP+1	;99H
;	LD	A,2	;S#2
;	OUT	(C),A
;	LD	A,15+80H
;	OUT	(C),A	;SET S#2 READ
;;
;	LD	A,(WTVSYNCS)
;	LD	B,A	;NEXT WTVSYNCS
;	CP	1
;	JR	Z,WTVSYN1
;	JR	NC,WTVSYN2
;;
;WTVSYN0:	; NO VBI = 0
;	IN	A,(C)
;	AND	40H	;VERTIACL BLANKING INTERVAL
;	JR	Z,WTVSYNCE
;	INC	B	;B=1
;	JR	WTVSYNCE
;WTVSYN1:	; VBI EDGE = 1
;	INC	B	;B=2
;WTVSYN2:	; IN VBI = 2
;	IN	A,(C)
;	AND	40H	;VERTIACL BLANKING INTERVAL
;	JR	NZ,WTVSYNCE
;	LD	B,0
;WTVSYNCE:
;	XOR	A	;S#0
;	OUT	(C),A
;	LD	A,15+80H
;	OUT	(C),A	;SET S#0 READ (DEFAULT)
;;	EI
;	LD	A,B
;	LD	(WTVSYNCS),A
;	RET
;WTVSYNCS:
;	DB	0
;;--------------------------------------
;ENDIF
;;--------------------------------------

;--------------------------------------
ADDHLA:	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET

;--------------------------------------
; CHANGE to Z80 (SAVE OLD MODE)
CPUZ80:	LD	A,(GETCPU)
	OR	A
	RET	Z
	LD	A,(CHGCPU)
	OR	A
	RET	Z
	CALL	GETCPU
	LD	(CPUSAV),A
	OR	A
	RET	Z
	LD	A,80H	;Z80
	CALL	CHGCPU
	RET

;--------------------------------------
; CHANGE to SAVED CPU MODE
CPURES:	LD	A,(GETCPU)
	OR	A
	RET	Z
	LD	A,(CHGCPU)
	OR	A
	RET	Z
	LD	A,(CPUSAV)
	OR	80H
	CALL	CHGCPU
	RET

