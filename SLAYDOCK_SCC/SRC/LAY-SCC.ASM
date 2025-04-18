;=== SCC BUF CLEAR for LAYDOCK ===
; WITH DI
SCCSET:
	LD	HL,SCCWORK
	XOR	A
	LD	DE,SCCWORK+1
	LD	BC,SCCWKSZ-1
	LDIR

; SAVE PRIMARY SLOT & EXPAND SLOT
	IN	A,(PSLOT)
	RRA
	RRA
	RRA
	RRA
	AND	3	; GET PAGE 2 SLOT
	LD	E,A
	LD	D,0
	LD	HL,SLTTBL
	ADD	HL,DE
	LD	C,A
	LD	A,(HL)	; GET EXPAND SLOT SAVED VALUES
	RRA
	RRA	; PAGE2 EXSLOT << 2
	AND	0CH
	OR	C	; MERGE PSLOT
	LD	C,A
	;
	;OR 128 ; SET EXPAND FLAG
	LD	HL,EXPTBL
	ADD	HL,DE
	LD	A,(HL)
	AND	128
	OR	C	; MERGE EXPAND_FLAG+EXPAND_SLOT_NO+PRIMARY_SLOT_NO
	PUSH	AF

; EXPAND SLOT SUPPORT / CHANGE SLOT
	LD	A,(SCCSLTA)
	LD	HL,9000H
	CALL	ENASLT

; ENABLE SCC
	LD	A,3FH
	LD	(9000H),A

; WRITE SCC INITIAL PARAMETERS
	LD	HL,09800H
	LD	DE,0400H+127
	CALL	WAVSET
	LD	DE,0400H+129
	CALL	WAVSET
	LD	DE,0700H+255
	CALL	WAVSET
	LD	DE,0800H+255
	CALL	WAVSET

; RESTORE SLOT
	POP	AF
	LD	HL,9000H
	CALL	ENASLT

	RET


WAVSET:	LD	A,D
	LD	B,32
	JR	L_WAVM
WAVM:	SUB	D
L_WAVM:	LD	C,A
	SUB	127
	LD	(HL),A
	LD	A,C
	INC	HL
	SUB	D
	JP	C,WAVP
	DJNZ	L_WAVM
	RET

WAVP:	ADD	A,D
L_WAVP:	LD	C,A
	SUB	127
	LD	(HL),A
	LD	A,C
	INC	HL
	ADD	A,D
	JP	C,WAVM
	ADD	A,D
	JP	C,WAVM
	DJNZ	L_WAVP
	RET

