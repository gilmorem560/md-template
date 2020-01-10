*****************************************************************
* main.s							*
*								*
* Description	Graphics Subs					*
*								*
* Date		2019/12/31					*
* Author	MIG<segaloco@gmail.com>				*
*****************************************************************
; movemap - Moves graphical mappings to the VDP
; Variables:
;   a0 -> mapping table
;
; Graphic Table Format:
;   dc.w    numberOfSprites (max 0x40)
;   dc.l    mapdata00 ... mapdataFF

movemap:
    movem.l d0/a1-a2, -(sp)    ; backup d0, a1, a2
    
    move.w  (a0)+, d0
    beq.s   .done               ; on zero or too large size, return
    
    lea     ($C00000).l, a1     ; a1 -> vdp data
    lea     ($C00004).l, a2     ; a2 -> vdp control
    move.l  #$7E000002, (a2)    ; VRAM to BE00H (sprite table)
    
.domove:
    move.w  (a0)+, (a1)
    dbf     d0, .domove
    
.done:
    movem.l (sp)+, d0/a1-a2    ; restore d0, a1, a2
    rts
    
; ===============================================================
; movepalette - Moves graphical palettes to the VDP
; Variables:
;   a0 -> palette table
;
; Graphic Table Format:
;   dc.w    numberOfColors (max 0x40)
;   dc.l    paldata00 ... paldataFF

movepalette:
    movem.l d0/a1-a2, -(sp)    ; backup d0, a1, a2
    
    move.w  (a0)+, d0
    cmpi.b  #$3F, d0
    bhi.s   .done               ; on too large, return
    
    lea     ($C00000).l, a1     ; a1 -> vdp data
    lea     ($C00004).l, a2     ; a2 -> vdp control
    move.l  #$C0000000, (a2)    ; CRAM write
    
.domove:
    move.w  (a0)+, (a1)
    dbf     d0, .domove
    
.done:
    movem.l (sp)+, d0/a1-a2    ; restore d0, a1, a2
    rts
    
; ===============================================================
; movetiles - Moves graphical tiles to the VDP
; Variables:
;   a0 -> graphic table
;
; Graphic Table Format:
;   dc.w    numberOfTiles
;   dc.l    tiledata00 ... tiledataFF

movetiles:
    movem.l d0/a1-a2, -(sp)    ; backup d0, a1, a2
    
    move.w  (a0)+, d0
    beq.s   .done               ; on zero size, return
    
    lea     ($C00000).l, a1     ; a1 -> vdp data
    lea     ($C00004).l, a2     ; a2 -> vdp control
    ;todo: do this with DMA
    move.l  #$40000000, (a2)
    
.domove:
    move.w  (a0)+, (a1)
    dbf     d0, .domove
    
.done:
    movem.l (sp)+, d0/a1-a2    ; restore d0, a1, a2
    rts
