;===============================================================================
; xy_mk_5v_lib.asm - xy_mk_5v library file. Need xy_mk_5v_inc.inc & xy_mk_5v_extern.inc to use
;===============================================================================
include	'xy_mk_5v_inc.inc'
include	'..\macro\macro_inc.inc'
;===============================================================================
public	XY_MK_5V_Interrupt,XY_MK_5V_Init,XY_MK_5V_ReInit
public	xy_mk_5v_bytecount,xy_mk_5v_buff
;===============================================================================
xy_mk_5v_data	segment data
rseg			xy_mk_5v_data
dseg			at	END_OF_RAM-XY_MK_5V_BUFFSIZE-5
xy_mk_5v_bitcount:			ds	1
xy_mk_5v_bytecount:			ds	1
xy_mk_5v_bytecount_temp:	ds	1
xy_mk_5v_received_byte:		ds	1
xy_mk_5v_ptr:				ds	1
xy_mk_5v_checksum:			ds	1

xy_mk_5v_idata	segment idata
rseg			xy_mk_5v_idata
xy_mk_5v_buff:	ds	XY_MK_5V_BUFFSIZE

if USE_PSW_BITS = 0
xy_mk_5v_bdata			segment bit
rseg					xy_mk_5v_bdata
xy_mk_5v_preamb_ok:		dbit	1
xy_mk_5v_receive_compl:	dbit	1
public	xy_mk_5v_receive_compl
endif

xy_mk_5v_code	segment	code
rseg			xy_mk_5v_code
;===============================================================================
XY_MK_5V_Interrupt:
	mov		TL0,	#0															; reload only TL0, 256 cycles before overflow TH0
	push	ACC
	push	PSW
	jb		xy_mk_5v_preamb_ok,Check_Data
;-------------------------------------------------------------------------------
Check_Preamb:
	mov		A,		TH0
	cjne	A,		#0FFh,		Receive_Error
if USE_PSW_BITS = 1
	pop		PSW
	setb	xy_mk_5v_preamb_ok
	push	PSW
elseif USE_PSW_BITS = 0
	setb	xy_mk_5v_preamb_ok
else
	ERROR
endif
	jmp		Check_Low_Level
;===============================================================================
Check_Data:
	mov		A,		#0FEh
	subb	A,		TH0
	jz		$+4																	; short signal (log 0) will set the zero flag
	jnc		Receive_Error														; long signal (log 1) will set the carry flag
	mov		A,		xy_mk_5v_received_byte
	rlc		A																	; receive high bit forward
	mov		xy_mk_5v_received_byte,A
	djnz	xy_mk_5v_bitcount,Check_Low_Level
	mov		xy_mk_5v_bitcount,#XY_MK_5V_BITNUM
	mov		A,		xy_mk_5v_bytecount_temp
	jnz		Receive_data
;-------------------------------------------------------------------------------
Receive_len_count:
	mov		A,		xy_mk_5v_received_byte										; restore xy_mk_5v_received_byte in ACC
	clr		C
	subb	A,		#XY_MK_5V_BUFFSIZE+2										; check pack size (BUFFSIZE+2 because received checksum is not written to the buffer)
	jnc		Receive_Error
	mov		xy_mk_5v_checksum,xy_mk_5v_received_byte							; get base for checksum (DATA len + checksum len)
	mov		xy_mk_5v_bytecount_temp,xy_mk_5v_received_byte						; get DATA len + checksum len
	mov		xy_mk_5v_bytecount,xy_mk_5v_received_byte
	dec		xy_mk_5v_bytecount													; get DATA len only
	jmp		Check_Low_Level
;===============================================================================
Receive_data:
	mov		A,		xy_mk_5v_received_byte										; restore xy_mk_5v_received_byte in ACC
	djnz	xy_mk_5v_bytecount_temp,Save_receive_byte
;-------------------------------------------------------------------------------
	cjne	A,		xy_mk_5v_checksum,Receive_Error                             ; compare checksum
if	USE_PSW_BITS = 1
	pop		PSW
	setb	xy_mk_5v_receive_compl
	push	PSW
elseif	USE_PSW_BITS = 0
	setb	xy_mk_5v_receive_compl
else
	ERROR
endif
;-------------------------------------------------------------------------------
Receive_Error:
	clr		TR0																	; stop Timer0
if	XY_MK_5V_IRQ = INT0
	clr		EX0																	; disable XY_MK_5V_IRQ
elseif	XY_MK_5V_IRQ = INT1
	clr		EX1																	; disable XY_MK_5V_IRQ
else
	ERROR
endif
	jmp		End_Int
;===============================================================================
Save_receive_byte:
	xrl		xy_mk_5v_checksum,A													; update checksum
	push	0h
	mov		R0,		xy_mk_5v_ptr												; get actual pointer
	mov		@R0,	A															; write DATA
	pop		0h
	inc		xy_mk_5v_ptr														; update pointer
;-------------------------------------------------------------------------------
Check_Low_Level:
	mov		TH0,	#TH0_LOW_LVL												; reload only TH0, TL0 didn't overflow
	jbc		TF0,	Receive_Error												; check Timer0 overflow
	jnb		xy_mk_5v_pin,$-3
	mov		A,		TH0
	cjne	A,		#0FFh,Receive_Error
	mov		TL0,	#0
	mov		TH0,	#TH0_DATA
;-------------------------------------------------------------------------------
End_Int:
	pop		PSW
	pop		ACC
	reti
;===============================================================================
XY_MK_5V_Init:
;== setup timers & interrupts for AT89C1051 ====================================
	orl		TMOD,	#00000001b	  ; “imer0 mode
	;					 ||||
	;					 ||++------	“imer0 mode (01 - 16-bit, 10 - 8-bit with auto-reload, 11 - not available, functions the same as 01)
	;					 |+--------	—/“0: 0 - timer, 1 - counter
	;					 +---------	Gate_“0: 0-control by TR0, 1-control by TR0 & INT0

	orl		TCON,	#00000101b	  ; “imer0 control
	;				   ||||||
	;				   |||||+------	IT0 - INT0 type: 0 - by level, 1 - by front
	;				   ||||+-------	IE0 - request INT0 (if IT0=1, autoclear in heandler)
	;				   |||+--------	IT1 - INT1 type: 0 - by level, 1 - by front
	;				   ||+---------	IE1 - request INT1 (if IT1=1, autoclear in heandler)
	;				   |+----------	TR0 - “imer0 start
	;				   +-----------	TF0 - Timer0 overflow flag

if	XY_MK_5V_IRQ = INT1
	setb	IP.2					; increase the priority of INT1
endif

	orl		IE,		#10000010b	  ; Interrupts
	;				 ||||||||
	;				 |||||||+------	EX0 - INT0 interrupt enable
	;				 ||||||+-------	≈“0 - Timer0 interrupt enable
	;				 |||||+-------- EX1 - INT1 interrupt enable
	;				 ||||+--------- ≈“1 - reserv, not used
	;				 |||+---------- ES  - reserv, not used
	;				 ||+----------- ET2 - reserv, not used
	;				 |+------------ reserv, not used
	;				 +------------- ≈¿ - global interrupts enable
	
	ret
;===============================================================================
XY_MK_5V_ReInit:
	mov		TL0,	#0
	mov		TH0,	#TH0_PREAMB
	mov		xy_mk_5v_bitcount,#XY_MK_5V_BITNUM
	mov		xy_mk_5v_bytecount_temp,#0
	mov		xy_mk_5v_ptr,#xy_mk_5v_buff
	clr		xy_mk_5v_preamb_ok
	clr		xy_mk_5v_receive_compl
	jnb		xy_mk_5v_pin,$
;-------------------------------------------------------------------------------
	setb	TR0																	; start Timer0
if	XY_MK_5V_IRQ = INT0
	clr		IE0
	setb	EX0																	; enable XY_MK_5V_IRQ
elseif	XY_MK_5V_IRQ = INT1
	clr		IE1
	setb	EX1																	; enable XY_MK_5V_IRQ
else
	ERROR
endif
	ret
;===============================================================================
end
