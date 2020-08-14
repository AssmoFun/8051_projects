;===============================================================================
; fs1000a_lib.asm - fs1000a library file. Need fs1000a_inc.inc & fs1000a_extern.inc to use
;===============================================================================
include	'fs1000a_inc.inc'
include	'..\macro\macro_inc.inc'
;===============================================================================
public	FS1000A_send_pack
public	fs1000a_buff
;===============================================================================
fs1000a_data	segment data
rseg			fs1000a_data
dseg			at	END_OF_RAM-FS1000A_BUFFSIZE+1
fs1000a_buff:	ds	FS1000A_BUFFSIZE
;===============================================================================
fs1000a_code	segment	code
rseg			fs1000a_code
;===============================================================================
Preamb:
	clr		FS1000A_TRANSMIT_PIN
	call	Delay_1_cycle
	setb	FS1000A_TRANSMIT_PIN
	call	Delay_3_5_cycle														; 1 long 3 ms pulse
	call	Delay_3_5_cycle
	call	Delay_3_5_cycle
;-------------------------------------------------------------------------------
	mov		fs1000a_bitcount,#SHORT_IMPULSE_NUM+1 								; SHORT_IMPULSE_NUM short pulses
Loop_Short_Impulse:
	setb	FS1000A_TRANSMIT_PIN
	call	Delay_1_cycle
	clr		FS1000A_TRANSMIT_PIN
	call	Delay_1_cycle
	djnz	fs1000a_bitcount,Loop_Short_Impulse
;-------------------------------------------------------------------------------
	setb	FS1000A_TRANSMIT_PIN
	call	Delay_3_5_cycle														; 1 sync pulse (3.5 cycle high + 1.5 cycle low)
	clr		FS1000A_TRANSMIT_PIN
	call	Delay_1_5_cycle
	ret
;===============================================================================
Send_byte:
	mov		fs1000a_bitcount,#FS1000A_BITNUM
Loop_Send_byte:
	setb	FS1000A_TRANSMIT_PIN
	call	Delay_1_5_cycle														; 384 mks
	rlc		A																	; transmit high bit forward
	jnc		$+5
	call	Delay_1_cycle														; +256=640 mks
	clr		FS1000A_TRANSMIT_PIN
	call	Delay_1_5_cycle
	djnz	fs1000a_bitcount,Loop_Send_byte
	ret
;===============================================================================
FS1000A_send_pack:
if	USE_TRANSMIT_COMPL_PIN
	if	RESTORE_TRANSMIT_COMPL_PIN = 0
		setb	FS1000A_TRANSMIT_COMPL_PIN										; transmit start
	endif
endif
	mov		fs1000a_bytecount,A
	clr		C
	subb	A,		#FS1000A_BUFFSIZE+1											; check pack size
	jnc		Wrong_param
	call	Preamb
	mov		A,		fs1000a_bytecount											; take the number of bytes
	inc		A																	; add checksum byte
	mov		fs1000a_checksum,A													; take as a basis for the checksum
	call	Send_byte															; send len pack
Loop_send_pack:
	mov		A,		@R0															; get byte from buffer
	xrl		fs1000a_checksum,A													; update checksum
	call	Send_byte															; send DATA
	inc		R0																	; update DATA pointer
	djnz	fs1000a_bytecount,Loop_send_pack
	mov		A,		fs1000a_checksum
	call	Send_byte															; send checksum
if	USE_TRANSMIT_COMPL_PIN
	clr		FS1000A_TRANSMIT_COMPL_PIN											; transmit OK
	if	RESTORE_TRANSMIT_COMPL_PIN
		nop																		; 2 nop for slow master MCU
		nop
	setb	FS1000A_TRANSMIT_COMPL_PIN
	endif
endif
Wrong_param:
	ret
;===============================================================================
;	For 12MHz 1 cycle = 256 mks, for 24MHz 1 cycle = 128 mks
;-------------------------------------------------------------------------------
Delay_1_cycle:
	mov		fs1000a_delay,#127
	djnz	fs1000a_delay,$
	ret
;-------------------------------------------------------------------------------
Delay_1_5_cycle:
	mov		fs1000a_delay,#190
	djnz	fs1000a_delay,$
	ret
;-------------------------------------------------------------------------------
Delay_3_5_cycle:
	call	Delay_1_5_cycle
	djnz	fs1000a_delay,$														; + 2 cycle
	ret
;===============================================================================
end
