; SCC Cartridges Search v0.9 by GDX


#include "MAIN-ROM.ASM"	; Labels for the MAIN-ROM
#include "SYS-VAR.ASM"	; Labels for the system variables

CR	equ	0Dh
LF	equ	0Ah

SCCtbl:	equ	0C000h

	org	0100h

	jp	START

TITLE_TXT:
	db	"SCC Cartridges Search v0.9",LF,CR,LF,"$",1ah
START:
	ld	de,TITLE_TXT
	call	PRINT

	ld	hl,SCCtbl
	call	SCCDetect

	ld	de,SCC_SLT_TXT
	call	PRINT

	ld	hl,SCCtbl
	xor	a
	cp	(hl)
	jp	z,NO_SCC

PrintTbl:
	push	hl
	ld	a,(hl)
	and	3
	add	a,030h
	ld	e,a
	ld	c,2	; Print a character (Primary slot number)
	call	BDOS

	pop	hl
	push	hl
	ld	a,(hl)	
	and	80h
	jr	z,PrimSLT
	
	ld	e,"-"
	ld	c,2	; Print a character
	call	BDOS

	pop	hl
	push	hl
	ld	a,(hl)	
	and	0ch
	rrca
	rrca
	add	a,030h
	ld	e,a
	ld	c,2	; Print a character (Secondary slot number)
	call	BDOS
PrimSLT:
	pop	hl
	inc	hl
	xor	a
	cp	(hl)
	jr	z,TblEnd	; Jump if 0 (end of the table)
	push	hl

	ld	e,2ch	; ','
	ld	c,2	; Print a character (',')
	call	BDOS
	pop	hl

	jp	PrintTbl

TblEnd:
	ld	e,LF
	ld	c,2	; Print a character
	call	BDOS
	ld	e,CR
	ld	c,2	; Print a character
	call	BDOS

	rst	0	; Back to the DOS

NO_SCC:

	ld	de,NOT_FND_TXT
	call	PRINT
	rst	0	; Back to the DOS

PRINT:
	ld	c,9	; Print a string
	jp	BDOS

;------------------------------------------
; SCC detection routine by gdx
; Input: HL= Table for slots with SCC inserted
; Output: HL= Table of slots with SCC inserted (0 at table end)
; Changes: All registers
;------------------------------------------

SCCDetect:
	push	hl
	ld	de,0		; E = Primary slot
SCCDetectLp:
	ld	hl,EXPTBL
	add	hl,de
	ld	a,(hl)
	and	80h
	or	e		; Store primary slot number
	pop	hl
	call	ChkCurrentSlt	; Check the current primary slot (or secondary 0)
	push	hl
	bit	7,a
	jr	z,NoSecSlt
	ld	a,84h
	or	e
	pop	hl
	call	ChkCurrentSlt	; Check the current secondary slot 1
	push	hl
	ld	a,88h
	or	e
	pop	hl
	call	ChkCurrentSlt	; Check the current secondary slot 2
	push	hl
	ld	a,8Ch
	or	e
	pop	hl
	call	ChkCurrentSlt	; Check the current secondary slot 3
	push	hl
NoSecSlt:
	inc	e
	ld	a,4
	cp	e
	jp	nz,SCCDetectLp

	pop	hl
	ret

; Search the SCC on specified slot
; Input: A = Slot number
; Output: A = Slot number, Carry = 0 if not found
	
ChkCurrentSlt:
	push	hl
	push	de
	push	bc
	push	af

; Test if RAM at 08000h

	ld	hl,08000h
	call	RDSLT
	cpl			; Test with inverted bits
	ld	e,a
	ex	af,af'		; Store readed byte to A'
	pop	af		; A = current slot number
	push	af
	call	WRSLT		; 	
	pop	af		; A = current slot number
	push	af
	call	RDSLT
	cpl
	ld	e,a
	pop	af		; A = current slot number
	push	af
	call	WRSLT		; 	
	ex	af,af'		; Restore A
	cpl
	cp	e
	jr	z,SCCNotFnd	; Jump if RAM

	pop	af		; A = current slot number
	push	af
	ld	e,0h
	ld	hl,0BFFEh
	call	WRSLT		; Set ROM mode for all pages & SCC mode on the Sound Cartridge

	pop	af		; A = current slot number
	push	af
	ld	e,03Fh
	ld	hl,09000h
	call	WRSLT		; Enable the SCC registers

; Test if SCC register at 09800h

	ld	hl,09800h

	pop	af		; A = current slot number
	push	af
	call	RDSLT
	cpl			; Test with inverted bits
	ld	e,a
	ex	af,af'		; Store A
	pop	af		; A = current slot number
	push	af
	call	WRSLT
	pop	af		; A = current slot number
	push	af
	call	RDSLT
	ld	e,a
	ex	af,af'		; Restore A
	cp	e
	jr	nz,SCCNotFnd	; Jump if the read value is not the same
	cpl			; Test again with not inverted bits
	ld	e,a
	ex	af,af'		; Store A
	pop	af		; A = current slot number
	push	af
	call	WRSLT
	pop	af		; A = current slot number
	push	af
	call	RDSLT
	ld	e,a
	ex	af,af'		; Restore A
	cp	e
	jr	nz,SCCNotFnd	; Jump if the read value is not the same

; When the SCC is found

	pop	af
	pop	bc
	pop	de
	pop	hl
	ld	(hl),a		; Store the slot number in the table
	inc	hl
	push	af
	xor	a
	ld	(hl),a		; Write 0 to indicate the end of the table
	pop	af
	scf			; Carry = 1
	ret

; When the SCC is not found

SCCNotFnd:
	pop	af
	ex	af,af'
	pop	bc
	pop	de
	pop	hl
	xor	a
	ld	(hl),a		; Write 0 to indicate the end of the table
	ex	af,af'
	or	a		; Carry = 0
	ret

SCC_SLT_TXT:
	db	"SCC slots: $"
NOT_FND_TXT:
	db	"Not found!",CR,LF,"$"