;===============================================================================
include	'Libs\macro\macro_inc.inc'
include	'Libs\xy_mk_5v_lib\xy_mk_5v_extern.inc'
include	'Libs\soft_uart_lib\soft_uart_extern.inc'
;===============================================================================
if	DEBUG
LED_PORT	equ	P2
else
LED_PORT	equ	P1
endif
;===============================================================================
main_idata	segment idata
rseg		main_idata
iseg		at	04h																; Stack = 6 bytes
Stack:
;===============================================================================
main_code	segment code
rseg		main_code
cseg		at	0
	jmp		Init
org	03h																			; INT0 Interrupt
if	XY_MK_5V_IRQ = INT0
	jmp		XY_MK_5V_Interrupt
else
	; USER CODE START

	; USER CODE END
	reti
endif
org	0Bh																			; Timer0 Interrupt
	_stop_xy_mk_5v
	reti
org	13h																			; INT1 Interrupt
if	XY_MK_5V_IRQ = INT1
	jmp		XY_MK_5V_Interrupt
else
	; USER CODE START

	; USER CODE END
	reti
endif
;===============================================================================
Init:
if	DEBUG
	mov		LED_PORT,#00000000b
endif
	_init_stack
	_clear_RAM
	call	XY_MK_5V_Init
;===============================================================================
ReInit_XY_MK_5V:
	call    XY_MK_5V_ReInit
;===============================================================================
Main:
	; USER CODE START

	; USER CODE END
	jnb		TR0,Check_xy_mk_5v_receive_compl
	jmp		Main
Check_xy_mk_5v_receive_compl:
	jbc		xy_mk_5v_receive_compl,Receive_complete
	jmp		ReInit_XY_MK_5V
;===============================================================================
Receive_complete:
	mov		R0,		#xy_mk_5v_buff
if	DEBUG
	mov		LED_PORT,@R0
endif
	_put_soft_uart  xy_mk_5v_buff,xy_mk_5v_bytecount
	jmp		ReInit_XY_MK_5V
;===============================================================================
end
