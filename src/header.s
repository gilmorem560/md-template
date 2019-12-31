*****************************************************************
* header.s							*
*								*
* Description	Megadrive System Header				*
*								*
* Date		2019/12/31					*
* Author	MIG<segaloco@gmail.com>				*
*****************************************************************

;system header
system:     dc.b    'SEGA MEGA DRIVE '
copyright:  dc.b    '(C)SEGA 2019.DEC'
dom_name:   dc.b    'GAME                                            '
ovr_name:   dc.b    'GAME                                            '
code:       dc.b    'GM 00000000-00'
checksum:   dc.w    0                   ; will be applied after assembly
controls:   dc.b    'J               '
romsize:    dc.l    romstart, romend
ramsize:    dc.l    $FF0000, $FFFFFF
exram:      dc.b    '  ', %00100000, %00100000
exramsize:  dc.l    $20202020, $20202020
modem:      dc.b    '  '
modemcomp:  dc.b    '    '
modemver:   dc.b    '    '
memo:       dc.b    '                                          '
region:     dc.b    'JUE             '