;-----------------------------------------------------------------------;
;	   File Name - LOCK.A						;
;	   Copyright (c) 1995 Sega of America, Inc.			;
;	   All Rights Reserved.						;
;-----------------------------------------------------------------------;
;									;
;	  REVISION HISTORY:						;
;									;
;   name	date	comments					;
;   ----	-------	-----------------------------------		;
;   SFB	 	18DEC92	file created					;
;   DWM	 	25MAY93	cleared d0 before reading hardware id code	;
;   DWM	 	15JUN93	changed MsgPtr so the addresses were offsets	;
;			from the label MessageData.			;
;   DWM	 	15JUN93	changed MsgJapan per request from SOJ		;
;   JMY	 	17JAN95	modified code to accept new hardware enable	;
;			code (0..F) rather than U,J,E country ID code	;
;									;
;   Genesis territory lockout.  Advises the user of incompatibilities   ;
;   between the cartridge and the Genesis hardware.  Prevents carts	;
;   intended for one territory from being run on a Genesis from another ;
;   territory.								;
;									;
;   This code was written for use with the SNASM assembler.  It can be  ;
;   adapted for use with other assemblers with minor modifications.  See;
;   LOCK.DOC for instructions on using the territory lockout code.	;
;-----------------------------------------------------------------------;

CheckVDP:
		clr.l   d0		;must be empty for check to work properly
		move.b  $A10001,d0	;read hardware territory ID
		lsr.b   #6,d0		;get ID into range 0..3
		andi.b  #3,d0

chkJPNTSC:
		cmpi.b	#0,d0		;check for Japan,NTSC
		bne.s	chkJPPAL	;if not, check for next hardware ID
		lea.l   JPNTSC(pc),a6	;point to the first row of the ID code matrix
		bra.s	CheckCountry	;branch off
chkJPPAL:
		cmpi.b  #1,d0		;check for Japan,PAL
		bne.s	chkUSNTSC	;if not, check for next hardware ID
		lea.l	JPPAL(pc),a6	;point to the second row of the 4x16 matrix
		bra.s	CheckCountry	;branch off
chkUSNTSC:
		cmpi.b	#2,d0		;check for US & Brazil,NTSC
		bne.s	chkEHKPAL	;if not, check for next hardware ID
		lea.l	USNTSC(pc),a6	;point to the third row of the 4x16 matrix
		bra.s	CheckCountry	;branch off
chkEHKPAL:
		cmpi.b	#3,d0		;check for Europe&HongKong,PAL
		bne	TrapCheckVDP	;illegal hardware ID
		lea.l	EHKPAL(pc),a6	;point to the fourth row of the 4x16 matrix

CHECKCOUNTRY:
		clr.l	d6
		lea.l   $8801F0,a0	;point to country codes in ID block
		move.b	(a0),d6		;get value of country code in ID Table(8801F0)

		cmpi.b  #$40,d6		;ID code 0-9 is ascii code 30-39
		blt.s	OneToTen	;ID code A-F is ascii code 41-46

		move.b	#$37,d7		;minus hex 37 from ascii "A" ~ "F" to
		sub.b	d7,d6		;get ID into range A..F
		bra.s	GetEnableCode

OneTOTen:
		lsl.b   #4,d6		;drop off the high byte(left digit of ID code)
		lsr.b   #4,d6		;get ID into range 0..9: offset to the entry

GetEnableCode:
		move.b	d6,d7		;save a copy of ID in (0..F) for later use
		move.b	(a6,d6),d6	;point to the entry in the 4x16 matrix
		tst.b   d6		;test entry value: 0=enable	1=disable
		beq	 EndCheckVDP	;found it, ok to run the game

		lea.l   $C00000,a4	;VDP data port
		lea.l   $C00004,a5	;VDP control port

		move.w  #$8164,(a5)	;enable display, VINT on, DMA off
		move.w  #$8230,(a5)	;scroll A map starts at $C000
		move.w  #$8C81,(a5)	;40 column mode
		move.w  #$8F02,(a5)	;autoincrement = 2
		move.w  #$9001,(a5)	;scroll size = 64x32

		move.l  #$C0020000,(a5) ;CRAM write to color #1
		move.w  #$0EEE,(a4)	;set color 1 to white

		move.l  #$40000000,(a5) ;VRAM address for chars
		lea.l   AASCIIchars(pc),a0	;a0 -> charset for message
		move.w  #59-1,d0	;59 chars

		move.l  #$10000000,d2   ;set pixel mask

WriteCharSet:
		move.w  #8-1,d6		;8 rows per char

WriteChar:
		move.b  (a0)+,d1	;get a row (source is 1 bit per pixel)
		move.l  #0,d4		;clear pixel row accumulator
		move.w  #8-1,d5		;8 pixels per row

WritePix:
		rol.l   #4,d2		;rotate masks to next pixel position

		ror.b   #1,d1		;check next bit in source
		bcc.s   NextPix		;if it's 0, don't put a pixel

		or.l	d2,d4		;else, put a pixel

NextPix:
		dbf	d5,WritePix	;next pixel

WritePixRow:
		move.l  d4,(a4)		;put pixel row in VRAM
		dbf	d6,WriteChar	;next row

		dbf	d0,WriteCharSet ;next char


;		lea.l   $1F0,a1		;point to territory ID's in ID block
;;the value for $1F0 is saved in D7 in the format of (0..F)

CheckID:				;Print Msgs for ID code: 1,4,5,A,B,C,E only
CheckID1:
		cmp.b   #1,d7		;if this entry in ID block = Japan NTSC?
		bne.s	CheckID4	;if not, check for next ID
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintJPN	;print msg for Japan, Korea, Taiwan territory
		bra	CheckIDDone	;print "systems" msg, DONE!

CheckID4:
		cmp.b	#4,d7		;US NTSC?
		bne.s	CheckID5	;if not, check for next ID
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintUSA	;print msg for USA, Brazil territory
		bra	CheckIDDone
CheckID5:
		cmp.b	#5,d7		;US NTSC and Japan NTSC?
		bne.s	CheckIDA	;
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintUSA	;print msg for USA
		bsr	PrintAND	;print "AND" msg
		bsr	PrintJPN	;print msg for Japan
		bra	CheckIDDone	;print "systems" msg, DONE!
CheckIDA:
		cmp.b	#$A,d7  	;Europe PAL?
		bne.s	CheckIDB	;if not, check for next ID
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintEUR	;print msg for Europe
		bra	CheckIDDone	;print "systems" msg
CheckIDB:
		cmp.b	#$B,d7 		;Japan NTSC and Europe PAL?
		bne.s	CheckIDC	;if not, check for next ID
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintJPN	;print msg for Japan
		bsr	PrintAND	;print AND msg
		bsr	PrintEUR	;print msg for Europe
		bra	CheckIDDone	;print system msg, DONE!
CheckIDC:
		cmp.b	#$C,d7	   	;Europe PAL & US NTSC?
		bne.s	CheckIDE	;if not, check for next ID
		bra.s	MsgCandE	;same msg for both ID "C" and "E"
CheckIDE:
		cmp.b	#$E,d7 		;Europe PAL & US NTSC?
		bne.s	Others		;if not, no msg needs to be printed
MsgCandE:
		bsr	PrintDEV	;print "developed for" msg
		bsr	PrintUSA	;print msg for USA
		bsr	PrintAND	;print AND msg
		bsr	PrintEUR	;print msg for Europe
		bra	CheckIDDone	;print system msg, DONE!

Others:
		bra.s	TrapCheckVDP	;Dead Hang


CheckIDDone:
		lea.l   MsgSystems(pc),a0	;write last line of message.
		move.b  (a0)+,d0
		addq.w  #1,d1
		bsr	 WriteString

TrapCheckVDP:
		bra.w	error

;;TrapCheckVDP:
;;		bra.s	TrapCheckVDP


PrintDEV:
		move.b  #8,d1		;set row for WriteString
		lea.l   MsgDevelopedFor(pc),a0	;set string address for WriteString
		move.b  (a0)+,d0	;set column for WriteString
		bsr	 WriteString	;write it to the screen
		rts

PrintJPN:
		lea.l	MsgJapan(pc),a0	;set string address for WriteString
		move.b  (a0)+,d0	;set column for WriteString
		addq.w  #1,d1		;next line
		bsr	 WriteString	;write it to the screen
		rts

PrintUSA:
		lea.l	MsgUSA(pc),a0	;set string address for WriteString
		move.b  (a0)+,d0	;set column for WriteString
		addq.w  #1,d1		;next line
		bsr	 WriteString	;write it to the screen
		rts

PrintEUR:
		lea.l	MsgEurope(pc),a0	;set string address for WriteString
		move.b  (a0)+,d0	;set column for WriteString
		addq.w  #1,d1		;next line
		bsr	 WriteString	;write it to the screen
		rts

PrintAND:
		lea.l	MsgAND(pc),a0   ;set string address for WriteString
		move.b  (a0)+,d0	;set column for WriteString
		addq.w  #1,d1		;next line
		bsr	 WriteString	;write it to the screen
		rts

WriteString:
		move.b  d1,d2
		and.l   #$FF,d2
		swap	d2
		lsl.l   #7,d2
		move.b  d0,d3
		and.l   #$FF,d3
		swap	d3
		asl.l   #1,d3
		add.l   d3,d2
		add.l   #$40000003,d2
		move.l  d2,(a5)

ws01:
		tst.b   (a0)
		beq.s   ws99
		move.b  (a0)+,d2
		sub.b   #' ',d2
		andi.w  #$FF,d2
		move.w  d2,(a4)
		bra.s   ws01

ws99:
		rts

MessageData:

HWEnableCodes:	;4x16 matrix for Hardware enable code ($1F0)
;;		0 1 2 3 4 5 6 7 8 9 A B C D E F
JPNTSC:
	dc.b	1,0,1,0,1,0,1,0,1,0,1,0,1,0,1,0
JPPAL:
	dc.b	1,1,0,0,1,1,0,0,1,1,0,0,1,1,0,0
USNTSC:
	dc.b	1,1,1,1,0,0,0,0,1,1,1,1,0,0,0,0
EHKPAL:
	dc.b	1,1,1,1,1,1,1,1,0,0,0,0,0,0,0,0



;			0123456789012345678901234567890123456789
MsgDevelopedFor:
	dc.b	6,	     'DEVELOPED FOR USE ONLY WITH',0
MsgAnd:
	dc.b	18,			 '&',0
MsgSystems:
	dc.b	15,		      'SYSTEMS.',0
MsgJapan:
	dc.b	12,		   'NTSC MEGA DRIVE',0
MsgUSA:
	dc.b	13,		    'NTSC GENESIS',0
MsgEurope:
	dc.b	4,	   'PAL AND FRENCH SECAM MEGA DRIVE',0


AASCIIchars:
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000000000000000000000000000	   ;' '
	dc.l	%00011000000110000001100000011000
	dc.l	%00000000000110000001100000000000	   ;!
	dc.l	%00110110001101100100100000000000
	dc.l	%00000000000000000000000000000000	   ;"
	dc.l	%00010010000100100111111100010010
	dc.l	%01111111001001000010010000000000	   ;#
	dc.l	%00001000001111110100100000111110
	dc.l	%00001001011111100000100000000000	   ;$
	dc.l	%01110001010100100111010000001000
	dc.l	%00010111001001010100011100000000	   ;%
	dc.l	%00011000001001000001100000101001
	dc.l	%01000101010001100011100100000000	   ;&
	dc.l	%00110000001100000100000000000000
	dc.l	%00000000000000000000000000000000	   ;'
	dc.l	%00001100000100000010000000100000
	dc.l	%00100000000100000000110000000000	   ;(
	dc.l	%00110000000010000000010000000100
	dc.l	%00000100000010000011000000000000	   ;)
	dc.l	%00000000000010000010101000011100
	dc.l	%00101010000010000000000000000000	   ;*
	dc.l	%00001000000010000000100001111111
	dc.l	%00001000000010000000100000000000	   ;+
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000001100000011000001000000	   ;,
	dc.l	%00000000000000000000000001111111
	dc.l	%00000000000000000000000000000000	   ;-
	dc.l	%00000000000000000000000000000000
	dc.l	%00000000001100000011000000000000	   ;�
	dc.l	%00000001000000100000010000001000
	dc.l	%00010000001000000100000000000000	   ;/
	dc.l	%00011110001100110011001100110011
	dc.l	%00110011001100110001111000000000	   ;0
	dc.l	%00011000001110000001100000011000
	dc.l	%00011000000110000011110000000000	   ;1
	dc.l	%00111110011000110110001100001110
	dc.l	%00111000011000000111111100000000	   ;2
	dc.l	%00111110011000110000001100011110
	dc.l	%00000011011000110011111000000000	   ;3
	dc.l	%00000110000011100001111000110110
	dc.l	%01100110011111110000011000000000	   ;4
	dc.l	%01111110011000000111111001100011
	dc.l	%00000011011000110011111000000000	   ;5
	dc.l	%00111110011000110110000001111110
	dc.l	%01100011011000110011111000000000	   ;6
	dc.l	%00111111011000110000011000000110
	dc.l	%00001100000011000001100000000000	   ;7
	dc.l	%00111110011000110110001100111110
	dc.l	%01100011011000110011111000000000	   ;8
	dc.l	%00111110011000110110001100111111
	dc.l	%00000011011000110011111000000000	   ;9
	dc.l	%00000000000110000001100000000000
	dc.l	%00000000000110000001100000000000	   ;:
	dc.l	%00000000000110000001100000000000
	dc.l	%00000000000110000001100000100000	   ;;
	dc.l	%00000011000011000011000001000000
	dc.l	%00110000000011000000001100000000	   ;<
	dc.l	%00000000000000000111111100000000
	dc.l	%01111111000000000000000000000000	   ;=
	dc.l	%01100000000110000000011000000001
	dc.l	%00000110000110000110000000000000	   ;>
	dc.l	%00111110011000110000001100011110
	dc.l	%00011000000000000001100000000000	   ;?
	dc.l	%00111100010000100011100101001001
	dc.l	%01001001010010010011011000000000	   ;@
	dc.l	%00011100000111000011011000110110
	dc.l	%01111111011000110110001100000000	   ;A
	dc.l	%01111110011000110110001101111110
	dc.l	%01100011011000110111111000000000	   ;B
	dc.l	%00111110011100110110000001100000
	dc.l	%01100000011100110011111000000000	   ;C
	dc.l	%01111110011000110110001101100011
	dc.l	%01100011011000110111111000000000	   ;D
	dc.l	%00111111001100000011000000111110
	dc.l	%00110000001100000011111100000000	   ;E
	dc.l	%00111111001100000011000000111110
	dc.l	%00110000001100000011000000000000	   ;F
	dc.l	%00111110011100110110000001100111
	dc.l	%01100011011100110011111000000000	   ;G
	dc.l	%01100110011001100110011001111110
	dc.l	%01100110011001100110011000000000	   ;H
	dc.l	%00011000000110000001100000011000
	dc.l	%00011000000110000001100000000000	   ;I
	dc.l	%00001100000011000000110000001100
	dc.l	%11001100110011000111100000000000	   ;J
	dc.l	%01100011011001100110110001111000
	dc.l	%01101100011001100110001100000000	   ;K
	dc.l	%01100000011000000110000001100000
	dc.l	%01100000011000000111111100000000	   ;L
	dc.l	%01100011011101110111111101101011
	dc.l	%01101011011000110110001100000000	   ;M
	dc.l	%01100011011100110111101101111111
	dc.l	%01101111011001110110001100000000	   ;N
	dc.l	%00111110011000110110001101100011
	dc.l	%01100011011000110011111000000000	   ;O
	dc.l	%01111110011000110110001101111110
	dc.l	%01100000011000000110000000000000	   ;P
	dc.l	%00111110011000110110001101100011
	dc.l	%01101111011000110011111100000000	   ;Q
	dc.l	%01111110011000110110001101111110
	dc.l	%01101000011001100110011100000000	   ;R
	dc.l	%00111110011000110111000000111110
	dc.l	%00000111011000110011111000000000	   ;S
	dc.l	%01111110000110000001100000011000
	dc.l	%00011000000110000001100000000000	   ;T
	dc.l	%01100110011001100110011001100110
	dc.l	%01100110011001100011110000000000	   ;U
	dc.l	%01100011011000110110001100110110
	dc.l	%00110110000111000001110000000000	   ;V
	dc.l	%01101011011010110110101101101011
	dc.l	%01101011011111110011011000000000	   ;W
	dc.l	%01100011011000110011011000011100
	dc.l	%00110110011000110110001100000000	   ;X
	dc.l	%01100110011001100110011000111100
	dc.l	%00011000000110000001100000000000	   ;Y
	dc.l	%01111111000001110000111000011100
	dc.l	%00111000011100000111111100000000	   ;Z

EndCheckVDP:

;-----------------------------------------------------------------------;
;	   File Name - LOCK.ASM						;
;	   Copyright (c) 1995 Sega of America, Inc.			;
;	   All Rights Reserved.						;
;-----------------------------------------------------------------------;
;	   End of file							;
;-----------------------------------------------------------------------;