*****************************************************************
* vector.s							*
*								*
* Description	M68000 vector table				*
*								*
* Date		2019/12/31					*
* Author	MIG<segaloco@gmail.com>				*
*****************************************************************

;vector table
	dc.l    $FFFFFE00, entry, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    0, 0, 0, 0
	dc.l    0, 0, 0, 0
	dc.l    nullexcep, nullexcep, nullexcep, nullexcep
	dc.l    nullexcep, nullexcep, nullexcep, nullexcep
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error
	dc.l    error, error, error, error