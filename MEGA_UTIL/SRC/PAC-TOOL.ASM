; for AILZ80ASM
; https://github.com/AILight/AILZ80ASM/

#pragma once

	include "ex-bios.asm"

;EXPTBL:	EQU	0FCC1H
;ENASLT:	EQU	00024H
;CHGSLT	... CHGSLT.ASM

PACSW:	equ	05FFEH	; SRAM Siwtch
PACMGN:	equ	0694DH	; SRAM Switch value
PACTST:	equ	04010H

PACSRM: EQU	04000H	; PAC SRAM START ADDRESS
PACBLM:	EQU	8	; PAC BLOCK MAX
PACBLS:	EQU	400H	; PAC BLOCK SIZE 1024

; PAC SRAM: $4000-$5FFD

;--------------------------------------
; LOAD FROM PAC SRAM
;--------------------------------------
;in:	a = slot No.
;	hl = read buffer address
;	c = start block (1-8)
;	b = block size (1-8)
;out:	interrupt = di
;use	all
LOADPAC:
	push	af
	
	push	hl
	push	bc
	call	ENAPAC
	pop	bc
	pop	hl
	
	ld	de,PACSRM
	ld	a,c
	dec	a	; block 1 = +0000h
	rlca
	rlca
	add	a,d
	ld	d,a	;de = de+c*400h
	
	ld	a,b
	rlca
	rlca
	ld	b,a
	ld	c,0	;bc = b*400h
	ex	de,hl	;de = dest / hl = source
	ldir
	
	pop	af
	call	DISPAC
	ret

;--------------------------------------
; SACE TO PAC SRAM
;--------------------------------------
;in:	a = slot No.
;	hl = write buffer address
;	c = start block (1-8)
;	b = block size (1-8)
;out:	interrupt = di
;use	all
SAVEPAC:
	push	af

	push	hl
	push	bc
	call	ENAPAC
	pop	bc
	pop	hl
	
	ld	de,PACSRM
	ld	a,c
	dec	a	; block 1 = +0000h
	rlca
	rlca
	add	a,d
	ld	d,a	;de = de+c*400h
	
	ld	a,b
	rlca
	rlca
	ld	b,a
	ld	c,0	;bc = b*400h
	ldir
	
	pop	af
	call	DISPAC
	ret

;--------------------------------------
; Enable PAC SRAM
;--------------------------------------
;in:	a = slot No.
;out:	interrupt = di
;use	all
ENAPAC:
	ld	hl,(PACSW)
	ld	(DISPACV+1),hl	; save value / code over write

	ld	hl,4000h
	call	CHGSLT

	ld	hl,PACMGN	; SRAM ON
	ld	(PACSW),hl
	ret

;--------------------------------------
; Disable PAC SRAM
;--------------------------------------
;in:	a = slot No.
;out:	interrupt = di
;use	all
DISPAC:
	ld	hl,4000h
	call	CHGSLT

DISPACV:
	ld	hl,0		;restore value
	ld	(PACSW),hl
	ret

;--------------------------------------
; Search PAC SLOT
;--------------------------------------
;out:	 a = PAC slot No. / $FF:no PAC
;	interrupt = di
CHKPAC:
	ld	c,1		; base slot 1
	ld	ix,S_ChkPAC
	call	_SltChk
	ret	nz
	ld	c,2		; base slot 2
	ld	ix,S_ChkPAC
	call	_SltChk
	ret	nz
	ld	a,0FFh
	ret

; check sub
;in:	a = slot
;out: 	z=NG / nz=OK
;use	all
S_ChkPAC:
	ld	(O_ChkPAC+1),a	; save slot No / code over write

	push	ix
	ld	hl,4000h
	call	CHGSLT
	pop	ix
	
	ld	hl,(PACSW)	; save original value
	push	hl
	
	ld	hl,0
	call	S_ChkPAC_
	jr	z,E_ChkPAC	; normal ram
	
	ld	hl,PACMGN	; PAC SRAM Magic No.
	call	S_ChkPAC_
	jr	nz,E_ChkPAC	; not pac sram
O_ChkPAC:
	ld	a,0		; ok = slot no.
	or	a		; nz (slot 0à»äOÇä˙ë“ÇµÇƒÇ¢ÇÈÅj
	jr	R_ChkPAC
E_ChkPAC:
	xor	a
R_ChkPAC:
	pop	hl
	ld	(PACSW),hl	; restore PAC SRAM Switch
	ret
	
S_ChkPAC_:
	ld	(PACSW),hl	; change PAC SRAM Switch
	ld	hl,PACTST
	ld	a,(hl)
	cpl
	ld	(hl),a
	cp	(hl)
	cpl
	ld	(hl),a
	ret

; (check slot/exp slot)
;in:	c = base slot
;	ix = check program address
;		in:	a=slot
;		out: 	z=NG / nz=OK
;out: 	z = NG / nz=OK
_SltChk:
	ld	hl,EXPTBL
	ld	a,c
	call	_AddHLA
	ld	a,(hl)	;expslt check
	and	80h
	ld	a,c
	jr	nz,_ExpSltC
	jp	_jp_ix
; (check exp slot)
_ExpSltC:
	ld	b,04h
	or	80h
	ld	c,a
_ExpSltL:
	ld	a,c
	push	bc
	call	_jp_ix
	pop	bc
	ld	a,c
	ret	nz
	add	a,04h	;EXPSLT+1
	ld	c,a
	djnz	_ExpSltL
	xor	a	;z
	ret

_jp_ix:
	jp	(ix)

_AddHLA:
	ADD	A,L
	LD	L,A
	RET	NC
	INC	H
	RET

;--------------------------------------
	; ENASLT CLONE (FOR PAGE 0 SLOT CHANGE)
;	INCLUDE "CHGSLT.ASM" ;*FILE*
;--------------------------------------
