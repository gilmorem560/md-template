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
;	INCLUDE	"SRC/SEGA/LOCK.S"

checksumcheck:
	; todo: create checksum calculation routine

; ---------------------------------------------------------------
; start game init on successful init
gameinit:
	; game init code goes here
	move	#$2700, sr	; mask interrupts for program init
	moveq	#0, d0
	tst.l	d0
	beq.w	mainloop
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
	lea     ($C00004).l, a0     ; vdp init, to optimize later
	move.w  #$8016, (a0)        ; H Int, no H/V
	move.w  #$8164, (a0)        ; V Int, display on , V 28
	move.w  #$8230, (a0)        ; Scroll A:     C000H
	move.w  #$832C, (a0)        ; Window:       B000H
	move.w  #$8407, (a0)        ; Scroll B:     E000H
	move.w  #$855F, (a0)        ; Sprite Attr:  BE00H
	move.w  #$8700, (a0)        ; Background color: 0,0
	move.w  #$8B00, (a0)        ; No Ext Int, full scroll
	move.w  #$8C00, (a0)        ; H 32, 240p
	move.w  #$8D2E, (a0)        ; H Scroll:     B800H
	move.w  #$8F02, (a0)        ; word increment
	move.w  #$9001, (a0)        ; V 32, H 64
    
	lea     palette_bin(pc), a0     ; load palette
	jsr     movepalette(pc)

	lea     graphic_bin(pc), a0     ; load tiles
	jsr     movetiles(pc)
	
	lea     mapping_bin(pc), a0     ; load mappings
	jsr     movemap(pc)
	
	nop
	nop
	move.w	#1, d0		; next game mode - 01
	rts

; ===============================================================
; game mode 01 - move sprite
gamemode_01:
	movem.l	d1-d3/a1, -(sp)
	lea	mapping_bin(pc), a0
	lea	($C00000).l, a1
	move.w	(a0)+, d0	; x position
	move.w	(a0)+, d1	; priority
	move.w	(a0)+, d2	; tile #
	move.w	(a0)+, d3	; y position

.xpos:
	addi.w	#1, d0
	cmpi.w	#$100, d0	; add 1 to x pos until $100, then reset
	blo.s	.ypos
	move.w	#$80, d0

.ypos:
	addi.w	#1, d3
	cmpi.w	#$100, d3	; add 1 to y pos until $100, then reset
	blo.s	.map
	move.w	#$80, d3

.map
	move.l  #$7E000002, 4(a1)	; write to sprite table

	move.w	d0, (a1)		; write mapping
	move.w	d1, (a1)
	move.w	d2, (a1)
	move.w	d3, (a1)

	move.w	#2, d0		; next game mode - 02
	movem.l	(sp)+, d1-d3/a1
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
	move.w	#1, d0		; next game mode - 01
	rts
	
; ===============================================================
mapping_bin:
	dc.w    ((mapping_done-mapping_bin)/2)-2     ; number of words following
	dc.w    $80     		; vpos
	dc.w    %0000110000000000	; sprite priority stack
	dc.w    %0000000000000001	; flipping, plane priority, start tile
	dc.w    $80     		; hpos
mapping_done:

palette_bin:
	dc.w    ((palette_done-palette_bin)/2)-2     ; number of words following
	dc.w    $000        ; black
	dc.w    $EEE        ; white
palette_done:

graphic_bin:
	dc.w    ((graphic_done-graphic_bin)/2)-2    ; number of words following
    
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000
	dc.l    $00000000   ; blank
    
	dc.l    $11111111
	dc.l    $11111111
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000   ; T
    
	dc.l    $11111111
	dc.l    $11111111
	dc.l    $11000000
	dc.l    $11111000
	dc.l    $11111000
	dc.l    $11000000
	dc.l    $11111111
	dc.l    $11111111   ; E
    
	dc.l    $11111111
	dc.l    $11111111
	dc.l    $11000011
	dc.l    $00111000
	dc.l    $00011100
	dc.l    $11000011
	dc.l    $11111111
	dc.l    $11111111   ; S
    
	dc.l    $11111111
	dc.l    $11111111
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000
	dc.l    $00011000   ; T
graphic_done:
	align 2
	
; ===============================================================
    INCLUDE     "SRC/LIBRARY/GRAPHICS.S"
; ===============================================================
; end of rom tag, used for some calculations
romend:	END