;===============================================================================
; xy_mk_5v_extern.inc - xy_mk_5v extern file. Need xy_mk_5v_lib.asm & xy_mk_5v_inc.inc to use
;===============================================================================
include	'Libs\xy_mk_5v_lib\xy_mk_5v_inc.inc'
;===============================================================================
extern	code	(XY_MK_5V_Interrupt,XY_MK_5V_Init,XY_MK_5V_ReInit)
extern	data	(xy_mk_5v_bytecount)
extern	idata	(xy_mk_5v_buff)
;===============================================================================
if	USE_PSW_BITS = 0
extern	bit	(xy_mk_5v_receive_compl)
endif
;===============================================================================
