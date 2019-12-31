*****************************************************************
* main.s							*
*								*
* Description	Main Game File					*
*								*
* Date		2019/12/31					*
* Author	MIG<segaloco@gmail.com>				*
*****************************************************************
; rom header
romstart:
	INCLUDE	"SRC/VECTOR.S"
	INCLUDE	"SRC/HEADER.S"
	INCLUDE "SRC/ERRORS.S"

; ---------------------------------------------------------------
; sega initial code
entry:
	INCLUDE	"SRC/SEGA/ICD_BLK4.S"
	INCLUDE	"SRC/SEGA/LOCK.S"

checksumcheck:
	; todo: create checksum calculation routine

; ---------------------------------------------------------------
; start game init on successful init
gameinit:
	; game init code goes here
	move.w	#$2700, sr	; mask interrupts for program init
	moveq	#0, d0
	tst.l	d0
	beq.s	mainloop
	bra.w	error		; d0 should still be zero

gamestart:
	andi.w	#$F8FF, sr	; unmask interrupts
	moveq	#0, d0		; next game mode - 00

mainloop:
	add.b	d0, d0
	andi.b	#3, d0		; maximum 3 modes currently
	move.w	gamemode(pc, d0.w), d0
	jsr	gamemode(pc, d0.w)
	bra.s	mainloop

; ---------------------------------------------------------------
; game mode jump table
gamemode:
	dc.w	gamemode_00-gamemode
	dc.w	gamemode_01-gamemode
	dc.w	gamemode_02-gamemode
	dc.w	gamemode_03-gamemode

; ===============================================================
; game mode 00 - null loop
gamemode_00:
	nop
	nop
	move.w	#1, d0		; next game mode - 01
	rts

; ===============================================================
; game mode 01 - null loop
gamemode_01:
	nop
	nop
	move.w	#2, d0		; next game mode - 02
	rts

; ===============================================================
; game mode 02 - null loop
gamemode_02:
	nop
	nop
	move.w	#3, d0		; next game mode - 03
	rts

; ===============================================================
; game mode 03 - null loop
gamemode_03:
	nop
	nop
	move.w	#0, d0		; next game mode - 00
	rts

; ===============================================================
; end of rom tag, used for some calculations
romend:	END