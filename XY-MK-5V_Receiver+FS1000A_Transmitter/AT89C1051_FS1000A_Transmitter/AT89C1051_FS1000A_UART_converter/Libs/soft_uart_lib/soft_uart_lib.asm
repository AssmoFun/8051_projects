;===============================================================================
; soft_uart_lib.asm - soft_uart library file. Need soft_uart_inc.inc & soft_uart_extern.inc to use
;===============================================================================
include	'soft_uart_inc.inc'
;===============================================================================
if	TX_ENABLE
public	Put_soft_uart
endif
;-------------------------------------------------------------------------------
if	RX_ENABLE
public	Get_soft_uart
endif
;===============================================================================
soft_uart_code	segment	code
rseg			soft_uart_code
;===============================================================================
if	TX_ENABLE
Put_soft_uart_byte:										; DATA for sending must be in A
	mov		soft_uart_bitcount,#DATA_BITS
	clr		TX_PIN										; Drop line for START-bit
	mov		soft_uart_delay,#BIT_TIME					; Wait full bit-time
	djnz	soft_uart_delay,$							; For START-bit
Loop_Put_soft_uart_byte:
	rrc		A											; Move next bit into carry
	mov		TX_PIN,	C									; Write DATA bit
	mov		soft_uart_delay,#BIT_TIME					; Wait full bit-time
	djnz	soft_uart_delay,$							; For DATA bit
	djnz	soft_uart_bitcount,Loop_Put_soft_uart_byte
	setb	TX_PIN										; Set line high for STOP-bit
	mov		soft_uart_delay,#BIT_TIME					; Wait full bit-time
	djnz	soft_uart_delay,$							; For STOP-bit
	ret
;-------------------------------------------------------------------------------
Put_soft_uart:
	mov		soft_uart_bytecount,A
Loop_Put_soft_uart:
	mov		A,		@R0
	inc		R0
	call	Put_soft_uart_byte
	djnz	soft_uart_bytecount,Loop_Put_soft_uart
	ret
endif
;===============================================================================
if	RX_ENABLE
Receive_soft_uart_byte:
	mov		soft_uart_bitcount,#DATA_BITS
	mov		soft_uart_delay,#BIT_TIME/2					; Wait 1/2 bit-time
	djnz	soft_uart_delay,$
	jb		RX_PIN,	Byte_err							; Ensure valid START-bit
Loop_Get_soft_uart_byte:
	mov		soft_uart_delay,#BIT_TIME					; Wait full bit-time
	djnz	soft_uart_delay,$							; For DATA bit
	mov		C,		RX_PIN								; Read DATA bit
	rrc		A											; Shift it into ACC
	djnz	soft_uart_bitcount,Loop_Get_soft_uart_byte
if BIT_TIME != 6
	mov		soft_uart_delay,#BIT_TIME					; Wait bit-time
	djnz	soft_uart_delay,$
	jb		RX_PIN,	No_Byte_err							; Ensure valid STOP-bit
else
	ret
endif
Byte_err:
	setb	soft_uart_frame_err
No_Byte_err:
	ret													; Received DATA in A
;-------------------------------------------------------------------------------
Wait_first_soft_uart_byte:
	jb		RX_PIN,	$									; Wait for START-bit
	call	Receive_soft_uart_byte
	ret
;-------------------------------------------------------------------------------
Get_soft_uart_bytes:
	jnb		RX_PIN,	Start_bit_detected					; Wait for START-bit
	djnz	soft_uart_delay,$-3
	setb	soft_uart_frame_end
	ret
Start_bit_detected:
	call	Receive_soft_uart_byte
	ret
;-------------------------------------------------------------------------------
Get_soft_uart:
	mov		soft_uart_bytecount,#1
Loop_Get_soft_uart_1:
	call	Wait_first_soft_uart_byte					; get first byte
	jbc		soft_uart_frame_err,Loop_Get_soft_uart_1	; check error
Loop_Get_soft_uart_2:
	mov		@R0,	A									; save byte to buffer
	call	Get_soft_uart_bytes							; get next byte
	jbc		soft_uart_frame_end,Frame_End				; check frame end
	jbc		soft_uart_frame_err,Frame_Err				; check error
	inc		R0											; update pointer
	inc		soft_uart_bytecount							; update byte counter
	jmp		Loop_Get_soft_uart_2
Frame_End:
Frame_Err:
	mov		A,		soft_uart_bytecount					; return the number of bytes received
	ret
endif
;===============================================================================
end
