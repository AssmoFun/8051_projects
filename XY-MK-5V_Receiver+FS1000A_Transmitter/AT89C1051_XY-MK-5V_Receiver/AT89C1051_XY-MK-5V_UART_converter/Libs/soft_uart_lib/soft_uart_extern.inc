;===============================================================================
; soft_uart_extern.inc - soft_uart extern file. Need soft_uart_lib.asm & soft_uart_inc.inc to use
;===============================================================================
include	'Libs\soft_uart_lib\soft_uart_inc.inc'
;===============================================================================
if	TX_ENABLE
extern	code	(Put_soft_uart)
endif
;-------------------------------------------------------------------------------
if	RX_ENABLE
extern	code	(Get_soft_uart)
endif
;===============================================================================