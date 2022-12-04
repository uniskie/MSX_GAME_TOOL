;***************************
; THE HOBBIT LOADER (DISK)
;***************************

; for tniasm v0.45
; http://www.tni.nl/products/tniasm.html


VDP:		EQU		$98
BEEP:		EQU		$00C0
CHGMOD:		EQU		$005F
CHPUT:		EQU		$00A2

SCRMOD:		EQU		$FCAF
FORCLR:		EQU		$F3E9
SLTWRK:		EQU		$FD09
H_KEYI:		EQU		$FD9A
H_TIMI:		EQU		$FD9F

START@:		EQU		$FDA4

RDBUFF:		EQU		$9000

			FNAME	"HOBBIT.BIN"	;*BINHEAD*
			
;--> BIN FILE HEADER -->
			DB		$FE				;*BINHEAD*
			DW		ORGADR			;*BINHEAD*
			DW		ENDFL-1			;*BINHEAD*
			DW		ORGADR			;*BINHEAD*
;<-- BIN FILE HEADER <--

ORGADR:		EQU		0C000H
			ORG		ORGADR

			LD		 (ERROR+1),SP
			CALL	 SCRSET
			CALL	 HTLOAD
			CALL	 HBTITL
			CALL	 HBLOAD
			CALL	 HBTEND

			DI
			CALL		ALLRAM

			LD		HL,GO_
			LD		DE,START@
			LD		BC,SCRSET-GO_
			LDIR

			JP		START@

;-------------------------------------
; boot rutine
;-------------------------------------
GO_:		LD		A,4
			OUT		(VDP+1),A
			LD		A,14+$80
			OUT		(VDP+1),A
			XOR		A
			OUT		(VDP+1),A
			OUT		(VDP+1),A
			LD		HL,0
			LD		A,$F0
			LD		BC,VDP
L_GO_:		INIR
			DEC		A
			JR		NZ,L_GO_

			XOR		A
			OUT		(VDP+1),A
			LD		A,14+$80
			OUT		(VDP+1),A

			XOR		A
			OUT		(VDP+1),A
			LD		A,17+$80
			OUT		(VDP+1),A
			LD		BC,VDP+$803
			LD		HL,VDPDAT-GO_+START@
			OTIR

			LD		SP,$FFFE
			JP		$8620		; START HOBBIT

VDPDAT:		DB		$02,$C0,$06,$FF,$03,$3E,$00,$0F

;-------------------------------------
; initalize screen
;-------------------------------------
SCRSET:
			LD		HL,COLORS
			LD		DE,FORCLR
			LD		BC,3
			LDIR
			LD		A,4
			CALL		CHGMOD

			; COLOR PALETTE
			XOR		A
			OUT		(VDP+1),A
			LD		A,16+$80
			OUT		(VDP+1),A
			LD		HL,PALET
			LD		BC,VDP+$2002
			OTIR

			LD		HL,$2000
			LD		A,$EF
			CALL	FILVRM

			RET

COLORS:		DB		1,15,15

; MSX2 PALETTE
;PALET:		DB		$00,$0,$00,$0,$11,$6,$33,$7,$17,$1,$27,$3,$51,$1,$27,$6
;			DB		$71,$1,$73,$3,$61,$6,$64,$6,$11,$4,$65,$2,$55,$5,$77,$7

; MSX1 like PALETTE
PALET:		DB		$00,$0,$00,$0,$33,$5,$44,$6,$37,$2,$47,$3,$52,$3,$36,$5
			DB		$62,$3,$63,$4,$53,$6,$64,$6,$21,$4,$55,$3,$55,$5,$77,$7

FILVRM:		PUSH	AF
			CALL	SETWR0
			LD		BC,$1800
			POP		AF
L_FVRM:		OUT		(VDP),A
			DEC		C
			JP		NZ,L_FVRM
			DJNZ	L_FVRM
			RET
;-------------------------------------
; load title
;-------------------------------------
HTLOAD:		LD		DE,RDBUFF
			CALL	F_DMA

			LD		HL,FILE_0
			CALL	F_OPEN
			JP		NZ,ERROR

			LD		HL,$3000
			CALL	F_READ

			RET
FILE_0:		DB		'HOBBIT  DAT'		;*DM*

ERROR:		LD		SP,0000		;?
			EI
			CALL	BEEP
			LD		A,(SCRMOD)		;SCREEN NO.
			CALL	CHGMOD
			LD		HL,MERROR
			CALL	PUTMES
			RET
MERROR:		DB		'FILE READ ERROR !!'		;*DM*
			DB		$0A,$0D,'$'

PUTMES:		LD		A,(HL)
			CP		'$'
			RET		Z
			CALL	CHPUT
			JP		PUTMES

;-------------------------------------
; set vram address
;-------------------------------------
; CY= BIT 16
; C= $40:WRITE / $00:READ
;C113:
VSET:		LD		A,H
			RLA
			RLA
			RLA
			AND		7
			OUT		(VDP+1),A
			LD		A,14+$80
			OUT		(VDP+1),A
			LD		A,L
			OUT		(VDP+1),A
			LD		A,H
			AND		$3F
			OR		C
			OUT		(VDP+1),A
			RET


SETWR0:		OR		A
			LD		C,$40
			JP		VSET

SETWR1:		SCF
			LD		C,$40
			JP		VSET

;-------------------------------------
; change ALL PAGE SLOT to RAM
;-------------------------------------
ALLRAM:		IN		A,($A8)
			CALL	ALRAM@
			OUT		($A8),A
			LD		A,($FFFF)
			CPL
			CALL	ALRAM@
			LD		($FFFF),A
			RET
			
ALRAM@:		RLCA
			RLCA
			AND		3
			LD		B,A
			RLCA
			RLCA
			OR		B
			RLCA
			RLCA
			OR		B
			RLCA
			RLCA
			OR		B
			RET


;=====================================================
; The following code is restoration from disassembly 
;because the source file was lost.
;=====================================================


;======================================
; TITLE DRAW EFFECT
;======================================

HBTITL:
		DI
		LD		 HL,H_KEYI
		LD		 DE,O_KEYI
		LD		 BC,$0005
		LDIR
		
		LD		 A,$C3			; JP TITHK1
		LD		 HL,TITHK1		;
		LD		 (H_KEYI),A
		LD		 (H_KEYI+1),HL
		
		LD		 (COUNT1),A
		LD		 HL,HBTIT_E
		LD		 (HBTIT_E+1),HL
		EI
HBTIT_E:	;
		JP		 HBTIT_E

RSTHOK:	;$C17A
		DI
		LD		 HL,O_KEYI
		LD		 DE,H_KEYI
		LD		 BC,$0005
		LDIR
		RET

O_KEYI:	;$C187
		DS		5

;--------------------------------------
; WRITE CHR PAT GEN ANIMATION
TITHK1:
		DI
		LD		 A,(COUNT1)
		LD		 D,A
		INC		 A
		JP		 Z,TITHK1N	;$C1C6
		LD		 A,(COUNT0)
		INC		 A
		AND		 $01
		LD		 (COUNT0),A
		JP		 NZ,TITHK1E	;$C1C2
		LD		 A,D
		RRA
		OR		 $80
		LD		 (COUNT1),A
		LD		 D,A
		LD		 HL,$0000	; CHR GEN
		LD		 C,$40
		CALL	 VSET
		
		LD		 HL,RDBUFF
		LD		 BC,$0018
TITHK1L:
		LD		 A,(HL)
		INC		 HL
		AND		 D
		OUT		 (VDP),A
		DJNZ	 TITHK1L	;$C1B7
		DEC		 C
		JP		 NZ,TITHK1L	;$C1B7
TITHK1E:;$C1C2
		IN		 A,(VDP+1)
		EI
		RET

TITHK1N:;$C1C6:
		LD		 HL,TITHK2	;$C1E0
		LD		 (H_KEYI+1),HL
		LD		 HL,$2000
		LD		 (COUNT1),HL
		IN		 A,(VDP+1)
		EI
		RET

TITHK_E:;$C1D6:
		LD		 HL,RSTHOK
		LD		 (HBTIT_E+1),HL
		IN		 A,(VDP+1)
		EI
		RET

;--------------------------------------
; WRITE CHR COLOR ANIMATION
TITHK2:;$C1E0:
		LD		 A,(COUNT1)
		CP		 $08
		JP		 Z,TITHK_E	;$C1D6
		
		LD		 A,(COUNT0)
		INC		 A
		CP		 $02
		LD		 (COUNT0),A
		JP		 NZ,TITHK1E	;$C1C2

		XOR		 A
		LD		 (COUNT0),A

		LD		 HL,(COUNT1)
		PUSH	 HL
		INC		 HL
		LD		 (COUNT1),HL

		LD		 DE,$87FF	;$2000+1+$87FF = $A800
		ADD		 HL,DE
		LD		 DE,$0008

		EXX

		POP		 HL
		LD		 DE,$0008
		LD		 BC,$0300
TITHK2L:;$C20F:
		PUSH	 BC
		OR		 A
		LD		 C,$40
		CALL	 VSET

		POP		 BC
		ADD		 HL,DE
		EXX
		LD		 A,(HL)
		ADD		 HL,DE
		OUT		 (VDP),A
		EXX

		DEC		 BC
		LD		 A,B
		OR		 C
		JP		 NZ,TITHK2L
		IN		 A,(VDP+1)
		EI
		RET

COUNT0:	;C228:	
		DB		7	;RLCA

COUNT1:	;C229:
		DW		0

HBTEND:
		DI
		LD		 HL,H_KEYI
		LD		 DE,O_KEYI
		LD		 BC,$0005
		LDIR
		
		LD		 A,$C3
		LD		 HL,ENDHK1
		LD		 (H_KEYI),A
		LD		 (H_KEYI+1),HL
		
		LD		 HL,$2000
		LD		 (COUNT1),HL
		LD		 HL,HBTIT_E
		LD		 (HBTIT_E+1),HL
		
		LD		 HL,0
		XOR		 A
		LD		 C,A
		CALL	 VSET
		
		LD		 HL,RDBUFF
		LD		 BC,$0098
		LD		 A,$30
HBTE_L:	;C25E:
		INIR
		DEC		 A
		JP		 NZ,HBTE_L
		EI
		JP		 HBTIT_E

ENDHK2:	;$C268:
		DI
		LD		 A,(COUNT1)
		LD		 D,A
		OR		 A
		JP		 Z,ENDHK_E
		LD		 A,(COUNT0)
		INC		 A
		AND		 $01
		LD		 (COUNT0),A
		JP		 NZ,TITHK1E	;$C1C2
		LD		 A,D
		RRA
		AND		 $7F
		LD		 (COUNT1),A
		LD		 D,A
		LD		 HL,0
		LD		 C,$40
		CALL	 VSET
		LD		 HL,RDBUFF
		LD		 BC,$0018
ENDHK2L:;C293:
		LD		 A,(HL)
		INC		 HL
		AND		 D
		OUT		 (VDP),A
		DJNZ	 ENDHK2L
		DEC		 C
		JP		 NZ,ENDHK2L
		IN		 A,(VDP+1)
		EI
		RET

ENDHK1E:;C2A2:
		LD		 HL,ENDHK2
		LD		 (H_KEYI+1),HL
		LD		 A,$FF
		LD		 (COUNT1),A
		IN		 A,(VDP+1)
		EI
		RET

ENDHK_E:;$C2B1:
		LD		 HL,RSTHOK
		LD		 (HBTIT_E+1),HL
		IN		 A,(VDP+1)
		EI
		RET

ENDHK1:	;$C2BB:
		LD		 A,(COUNT1)
		CP		 $08
		JP		 Z,ENDHK1E
		LD		 A,(COUNT0)
		INC		 A
		CP		 $02
		LD		 (COUNT0),A
		JP		 NZ,TITHK1E	;$C1C2
		XOR		 A
		LD		 (COUNT0),A
		LD		 HL,(COUNT1)
		INC		 HL
		LD		 (COUNT1),HL
		DEC		 HL
		LD		 DE,$0008
		LD		 BC,$0300
ENDHK1L:;C2E1:
		PUSH	 BC
		OR		 A
		LD		 C,$40
		CALL	 VSET
		POP		 BC
		ADD		 HL,DE
		LD		 A,$EF
		OUT		 (VDP),A
		DEC		 BC
		LD		 A,B
		OR		 C
		JP		 NZ,ENDHK1L
		IN		 A,(VDP+1)
		EI
		RET

;======================================
; LOAD 'THE HOBBIT' GAME BINARY
;======================================
HBLOAD:
		LD		 DE,RDBUFF
		CALL	 F_DMA
		
		LD		 HL,0
		CALL	 SETWR1
		
		LD		 B,$05

HBLD_L:	;C306:
		PUSH	 BC
		LD		 HL,$3000
		CALL	 F_READ
		
		LD		 HL,RDBUFF
		LD		 BC,$0000+VDP
		LD		 A,$30

HBLDWL:
		OTIR
		DEC		 A
		JP		 NZ,HBLDWL
		
		POP		 BC
		DJNZ	 HBLD_L

; probably no use ... original loader
		LD		 HL,$0200
		CALL	 F_READ
		LD		 HL,RDBUFF
		LD		 DE,SLTWRK	;$FD09
		LD		 BC,$01A5
		LDIR

		RET

			INCLUDE	"FILEIN.ASM"	;*FILE*

ENDFL: