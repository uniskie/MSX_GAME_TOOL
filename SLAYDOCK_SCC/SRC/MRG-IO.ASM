;====== FILE I/O ======
BDOS:	EQU	0F37DH
DISKVE:	EQU	0F323H

_PRINT:	EQU	09H
_FOPEN:	EQU	0FH
_SETDMA:	EQU	1AH
_RDRND:	EQU	27H
_WRRND:	EQU	26H
_FCLOSE:	EQU	10H
_FMAKE:	EQU	16H
_FKILL:	EQU	13H
_FFIRST:	EQU	11H
_FMEXT:	EQU	12H



;=== SET DMA ===
;SET: DE= DMA ADDRESS

F_DMA:	LD	C,_SETDMA
	CALL	BDOS
	RET

;=== MAKE FILE ===
;USE: ALL
;SET: DE= not opened FCB ADDRESS
;OUT: A: RESULT

F_MAKE:	PUSH	DE
	LD	C,_FMAKE
	CALL	BDOS
	CALL	_FSET
	RET	Z
	CALL	ERROR
	DW	FMAKE_

;=== CLOSE FILE ===
;USE: ALL
;SET: DE= opened FCB ADDRESS
;OUT: A: RESULT

F_CLOSE:	LD	C,_FCLOSE
	CALL	BDOS
	OR	A
	RET	Z
	CALL	ERROR
	DW	FCLOSE_

;=== OPEN FILE ===
;USE: ALL
;SET: DE= opend FCB ADDRESS
;OUT: A= RESULT

F_OPEN:	PUSH	DE
	LD	C,_FOPEN
	CALL	BDOS
	CALL	_FSET
	RET	Z
	CALL	ERROR
	DW	FOPEN_

_FSET:	POP	HL
	POP	IX

	LD	(IX+14),00H
	LD	(IX+15),20H	;RECORD SIZE= 2000H bytes (8K bytes)

	LD	(IX+33),0
	LD	(IX+34),0
	LD	(IX+35),0
	LD	(IX+36),0	;RANDOM RECORD No.= 0

	OR	A
	JP	(HL)

;=== READ FILE ===
;USE: ALL
;SET: DE= opend FCB ADRESS
;     HL= RECORD � ���
;OUT: HL= �ޯ��� ���� ���

F_READ:	LD	C,_RDRND
	CALL	BDOS
	OR	A
	RET	Z
	CALL	ERROR
	DW	FREAD_

;=== WRITE FILE ===
;USE: ALL
;SET: DE= opend FCB ADRESS
;     HL= RECORD � ���
;     DMA= DATA(s)
;OUT: A: RESULT

F_WRITE:	LD	C,_WRRND
	CALL	BDOS
	OR	A
	RET	Z
	CALL	ERROR
	DW	FWRITE_

;====== ERROR !! ======
ERROR:	LD	DE,ERROR_
	CALL	F_PRINT
	POP	HL
	LD	E,(HL)
	INC	HL
	LD	D,(HL)
	CALL	F_PRINT
	LD	C,0
	CALL	BDOS	;BASIC WARM START

;=== print STRINGS ===
F_PRINT:	LD	C,_PRINT
	CALL	BDOS
	RET

BEEP:	EQU	6
ED:	EQU	'$'
LF:	EQU	10
HOME:	EQU	11
CLS:	EQU	12
CR:	EQU	13

;=== ERROR messages ===
ERROR_:	DB	BEEP,LF,ED
FMAKE_:	DB	'Too many files to make new file !!$'
FCLOSE_:	DB	'Can not close file !!$'
FOPEN_:	DB	'Can not open file !!$'
FREAD_:	DB	'Can not read file !!$'
FWRITE_:	DB	'Can not write file !!$'
