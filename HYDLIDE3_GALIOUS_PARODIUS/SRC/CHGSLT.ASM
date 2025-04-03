;-*- tab-width: 8 -*-

SLTTBL:	equ	0FCC5H	;Mirror of Ex-Slot Registers (x4slots)
SLOTIO:	equ	0A8H	;Slot I/O port
EXSLTR:	equ	0FFFFH	;Extended Slot Register
			;拡張スロットの場合は値を書き込んだ後に読み出すと、
			;書き込んだ値の反転した値となって読み出されます。
			;このレジスタは同一基本スロット内であれば、どの拡張スロットでも同じ値です。

;--------------------------------------
;CHANGE SLOT
; (Alternative ENASLT)
; - code on PAGE2 : works for PAGE 0-1
; - code on PAGE3 : works for PAGE 0-2
; - code on PAGE0 : works for PAGE 1-2
;
; IN:	HL=ADDRESS  
;	A=SLOT  
;	   X000EEBB  
;	   |   | +- BASE SLOT (0-3)  
;	   |   +- EXREND SLOT (0-3)  
;	   +- EXTEND FLAG  
;OUT:	---
;USE:	ALL
;--------------------------------------
CHGSLT:
	CALL	.MKSLTV
	JP	M,.CHGSLT_1	;SLOT bit7==1 ... EXTEND SLOT
	; BASIC SLOT
	IN	A,(SLOTIO)
	AND	C
	OR	B
	OUT	(SLOTIO),A
	RET
.CHGSLT_1:
	; EXTEND SLOT
	PUSH	HL
	CALL	.CHGEXSLT
	LD	C,A		;C=BASE SLOT
	LD	B,0
	LD	A,L
	AND	H
	OR	D		;SLOT TABLE VALUE
	LD	HL,SLTTBL	;EX SLOT TABLE ADDRESS
	ADD	HL,BC
	LD	(HL),A		;WRITE TO EX SLOT TABLE
	POP	HL
	LD	A,C		;A=C=BASE SLOT
	JR	CHGSLT

;--------------------------------------
; MAKE SLOT REGISTER MASK AND VALUE
;
; IN:	HL=ADDRESS
;	A=SLOT
;	   X000EEBB
;	   |   | +- BASE SLOT (0-3)
;	   |   +- EXREND SLOT (0-3)
;	   +- EXTEND FLAG
;OUT:	B=SLOT REGISTER VALUE
;	C=INVERTED PAGE MASK
;	E=PAGE MASK
;	A=SLOT
;	S=EXTEND FLAG
;--------------------------------------
.MKSLTV:
	DI
	PUSH AF
	LD	A,H
	RLCA
	RLCA
	AND	03H	;A[b1-0] <- HL[b15-14]
	LD	E,A	;E=PAGE

	LD	A,0C0H	; 1100 0000B
.MKSLTV_1:
	RLCA
	RLCA
	DEC	E
	JP	P,.MKSLTV_1	;PLUS VALUE (S==0 / Bit7==0)
	LD	E,A	;E=PAGE MASK

	CPL		;A=INVERT PAGE MASK
	LD	C,A	;C=INVERTED PAGE MASK

	POP	AF
	PUSH	AF
	AND	03H	;A = BASE SLOT

	LD	B,A
	INC	B	;B = BASE SLOT + 1
	LD	A,0ABH	; 10101011B (00000000B - 01010101B)
.MKSLTV_2:
	ADD	A,55H	; + 01010101B
			; 1. 00000000B
			; 2. 01010101B
			; 3. 10101010B
			; 4. 11111111B
	DJNZ	.MKSLTV_2
	LD	D,A		;D=BASE SLOT for ALL PAGES
	AND	E		; (E=PAGE MASK)
	LD	B,A		;B=SLOT OF PAGE (REG VALUE)
				;C=INVERTED PAGE MASK
	POP	AF
	AND	A		; (S,Z,PV / Cy=0, N=0, H=1)
	RET

;--------------------------------------
; CHANGE EXTEND SLOT
;
; IN:	HL=ADDRESS
;	A=SLOT
;	   X000EEBB
;	   |   | +- BASE SLOT (0-3)
;	   |   +- EXREND SLOT (0-3)
;	   +- EXTEND FLAG
;OUT:	D=EX-SLOT OF PAGE (REG VALUE)
;	E=PAGE MASK
;	H=INVERTED PAGE MASK
;	L=EXTEND SLOT REG VALUE
;	A=BASE SLOT
;--------------------------------------
.CHGEXSLT:
	PUSH	AF
	LD	A,D
	AND	0C0H
	LD	C,A
	POP	AF
	PUSH	AF
	LD	D,A
	IN	A,(SLOTIO)	;READ BASE SLOT REG
	LD	B,A
	AND	3FH
	OR	C
	OUT	(SLOTIO),A	;CHANGE PAGE3 BASE SLOT (FOR EXTEND SLOT REG)

	LD	A,D
	RRCA
	RRCA
	AND	03H
	LD	D,A		;D=EX SLOT NO.
	LD	A,0ABH	; 10101011B (00000000B - 01010101B)
.CHGEXSLT_1:
	ADD	A,55H	; + 01010101B
			; 1. 00000000B
			; 2. 01010101B
			; 3. 10101010B
			; 4. 11111111B
	DEC	D
	JP	P,.CHGEXSLT_1
	AND	E		;E=PAGE MASK
	LD	D,A		;D=EX-SLOT OF PAGE (REG VALUE)
	LD	A,E
	CPL
	LD	H,A		;H=INVERTED PAGE MASK
	LD	A,(EXSLTR)
	CPL
	LD	L,A		;L=EX SLOT REG VALUE
	AND	H		;A=EX-SLOT OF OTHER PAGE
	OR	D		;A=MIXED EX-SLOT REG VALUE
	LD	(EXSLTR),A	;CHANGE EXTEND SLOT
	LD	A,B
	OUT	(SLOTIO),A	;CHANGE BASE SLOT
	POP	AF
	AND	03H
	RET

