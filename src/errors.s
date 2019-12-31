*****************************************************************
* errors.s							*
*								*
* Description	Error Handler Vectors				*
*								*
* Date		2019/12/31					*
* Author	MIG<segaloco@gmail.com>				*
*****************************************************************
; generic error lock

error:
	nop
	nop
	bra.s	error

; ===============================================================
; null exception

nullexcep:
	nop
	nop
	rte