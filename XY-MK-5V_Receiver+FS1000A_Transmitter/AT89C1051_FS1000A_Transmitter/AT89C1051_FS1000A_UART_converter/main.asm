;===============================================================================
include	'Libs\macro\macro_inc.inc'
include	'Libs\fs1000a_lib\fs1000a_extern.inc'
include	'Libs\soft_uart_lib\soft_uart_extern.inc'
;===============================================================================
main_idata	segment idata
rseg		main_idata
iseg		at	5h                                                              ; Stack = 11 bytes
Stack:
;===============================================================================
main_code	segment code
rseg    	main_code
cseg		at	0h
;===============================================================================
	jmp     Init
org	03h																			; INT0 interrupt
;	jmp     Int_0
	reti
org	0Bh																			; Timer0 interrupt
;	jmp		Timer0_Int
	reti
org	13h																			; INT1 interrupt
;	jmp     Int_1
	reti
;===============================================================================
Init:
	_init_stack
	_clear_RAM
;== setup timers & interrupts for AT89C1051 ====================================
;	orl		TMOD,	#00000001b	  ; ?imer0 mode
	;					 ||||
	;					 ||++------	?imer0 mode (01 - 16-bit, 10 - 8-bit with auto-reload, 11 - not available, functions the same as 01)
	;					 |+--------	?/?0: 0 - timer, 1 - counter
	;					 +---------	Gate_?0: 0-control by TR0, 1-control by TR0 & INT0

;	orl		TCON,	#00000101b	  ; ?imer0 control
	;				   ||||||
	;				   |||||+------	IT0 - INT0 type: 0 - by level, 1 - by front
	;				   ||||+-------	IE0 - request INT0 (if IT0=1, autoclear in heandler)
	;				   |||+--------	IT1 - INT1 type: 0 - by level, 1 - by front
	;				   ||+---------	IE1 - request INT1 (if IT1=1, autoclear in heandler)
	;				   |+----------	TR0 - ?imer0 start
	;				   +-----------	TF0 - Timer0 overflow flag

;	orl		IE,		#10000010b	  ; Interrupts
	;				 ||||||||
	;				 |||||||+------	EX0 - INT0 interrupt enable
	;				 ||||||+-------	??0 - Timer0 interrupt enable
	;				 |||||+-------- EX1 - INT1 interrupt enable
	;				 ||||+--------- ??1 - reserv, not used
	;				 |||+---------- ES  - reserv, not used
	;				 ||+----------- ET2 - reserv, not used
	;				 |+------------ reserv, not used
	;				 +------------- ?? - global interrupts enable
;===============================================================================
Main:
	_get_soft_uart		fs1000a_buff,soft_uart_bytecount
if	DEBUG
	_put_soft_uart		fs1000a_buff,soft_uart_bytecount
else
	_fs1000a_send_pack	fs1000a_buff,soft_uart_bytecount
endif
	; USER CODE BEGIN

	; USER CODE END
	jmp     Main
;===============================================================================
end
