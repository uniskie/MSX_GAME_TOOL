;====== SLAYDOCK TOOLS COMMON LABELS ======

_LAYHEAD:	EQU	0F935H
SCCWORK:	EQU	0FB40H	; PLYCNT
SCCWKSZ:	EQU	110	; PLYCNT->110bytes
_OPTION:	EQU	0C800H

;==================
; scc
;===================
;SCCSLTN EQU 1 ;slot1
;SCCSLT  EQU 81H ;slot 1-0
;SCCSLTP EQU 10H ;page2=slot1
;SCCSLTE EQU 00H ;page2=slot?-0
SCCSLTN:	EQU	2	;slot2
SCCSLT:	 EQU 82H	;slot 2-0
SCCSLTP:	EQU	20H	;page2=slot2
SCCSLTE:	EQU	00H	;page2=slot?-0
PG2MSK:	EQU	030H
PG2NMSK:	EQU	0CFH
SCCMIX:	EQU	988FH

;===================
; Memory Mapper (WriteOnly)
;===================
MAP1:	EQU	0FDH
MAP2:	EQU	0FEH
MAP3:	EQU	0FFH
;==================
; default Memory Mapping
;===================
RAM0:	EQU	3
RAM1:	EQU	2
RAM2:	EQU	1
RAM3:	EQU	0

;===================
; HOOK
;===================
H_KEYI:	EQU	0FD9AH
H_TIMI:	EQU	0FD9FH
KEYIO1:	EQU	0A9H
KEYIO2:	EQU	0AAH

;===================
; SLOT WORK and I/O
;===================
;PSLOT/ESLOT/SLTTBL
;7|  :  |  :  |  :  |  :  |0
;  page3 page2 page1 page0

PSLOT:	EQU	0A8H	;base-slot register (2bit per page)
ESLOT:	EQU	0FFFFH	;exp-slot register (2bit per page)

EXPTBL:	EQU	0FCC1H	;MAIN-ROM SLOT No. / SLOT EXPAND FLAGS
;+0 bit7=Slot0 Expand Flag / bit2-3=MAIN-ROM ExSlot No. / bit1-0=MainROM BsSlot No.
;+1 bit7=Slot1 Expand Flag
;+2 bit7=Slot2 Expand Flag
;+3 bit7=Slot3 Expand Flag
EXBRSA:	EQU	0FAF8H	;SUB-ROM SLOT No.
SLTTBL:	EQU	0FCC5H	;+0 - +3 : ex-slot select save
RAMAD0:	EQU	0F341H	;ram slots DISK WORK = RAM SLOT

;===================
; SLOT BIOS
;===================
RDSLT:	EQU	000CH; read slot(A) address(HL) to A / use AF,BC,DE
WRSLT:	EQU	0014H	; write slot(A) address(HL) value(E) / use:AF,BC,D
CALSLT:	EQU	001CH	; call slot(IYh) address(IX) / use:?
ENASLT:	EQU	0024H	; change alot(A) / use:all
