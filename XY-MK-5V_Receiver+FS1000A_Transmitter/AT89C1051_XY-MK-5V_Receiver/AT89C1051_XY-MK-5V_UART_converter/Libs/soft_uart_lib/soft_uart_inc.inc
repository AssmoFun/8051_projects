;===============================================================================
; soft_uart_inc.inc - soft_uart include file. Need soft_uart_lib.asm & soft_uart_extern.inc to use
;===============================================================================
;Formula to calculate the bit time delay constant
;This constant is calculated as: (((crystal/baud)/12) - 5) / 2
;crystal is the frequency of crystal in Hz
;baud is required baudrate
;BIT_TIME			equ	0Ah				; (((11059200/9600)/12) - 5) / 2
F_CPU				set	12000000
CPU_CYCLE			equ	12				; CPU cycle (12 for classic 12-cycle clock, 2 for STC15)
BAUDRATE			equ	57600
BIT_TIME			equ	(((F_CPU/BAUDRATE)/CPU_CYCLE) - 5) / 2
;===============================================================================
RX_ENABLE			equ	0
TX_ENABLE			equ	1
;===============================================================================
RX_PIN				bit	P3.0			; Receive on this pin
TX_PIN				bit	P3.1			; Transmit on this pin
;===============================================================================
soft_uart_frame_err	bit	PSW.1
soft_uart_frame_end	bit	F0				; PSW.5
;===============================================================================
soft_uart_delay		equ	R1
soft_uart_bitcount	equ	R2
soft_uart_bytecount	equ	R3
;===============================================================================
DATA_BITS			equ	8
;===============================================================================
_get_soft_uart	macro	_BUFF,	size
				mov		R0,		#_BUFF
				call	Get_soft_uart
				mov		size,	A
				endm
;-------------------------------------------------------------------------------
_put_soft_uart	macro	_BUFF,	size
				mov		R0,		#_BUFF
				mov		A,		size
				call	Put_soft_uart
				endm
;===============================================================================
