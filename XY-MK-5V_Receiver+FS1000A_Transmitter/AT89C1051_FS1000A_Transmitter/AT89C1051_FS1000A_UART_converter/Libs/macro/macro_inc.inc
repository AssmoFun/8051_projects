;===============================================================================
; macro_inc.inc
;===============================================================================
DEBUG		equ	0
;===============================================================================
CPU_TYPE	equ	1051
;CPU_TYPE	equ	2051
;CPU_TYPE	equ	52
;CPU_TYPE	equ	8252
;-------------------------------------------------------------------------------
;F_CPU		equ	11059
F_CPU		equ	12000
;-------------------------------------------------------------------------------
USE_WDT		equ	0
;-------------------------------------------------------------------------------
if	CPU_TYPE	=	1051
END_OF_RAM	equ	63
elseif	CPU_TYPE =	2051
END_OF_RAM	equ	127
else
END_OF_RAM	equ 255
endif
;===============================================================================
; Initializing stack macro
;===============================================================================
_init_stack	macro
			mov		SP,		#stack
			endm
;===============================================================================
; Bank switching macro
;===============================================================================
_bank_0		macro
			anl		PSW,	#11100111b
			endm

_bank_1		macro
			setb	PSW.3
			clr		PSW.4
			endm

_bank_2		macro
			clr		PSW.3
			setb	PSW.4
			endm

_bank_3		macro
			orl		PSW,	#00011000b
			endm
;===============================================================================
; Memory cleanup macro
;===============================================================================
_clear_RAM	macro
			local	Loop_clear_RAM
			mov		R0,		#END_OF_RAM
		Loop_clear_RAM:
			mov		@R0,	#0
			djnz	R0,		Loop_clear_RAM
			endm
;===============================================================================
; Check bit & jump macro. Bit will be clened after check
;===============================================================================
_jbc		macro	flag,label
			jbc		flag,$+5
			jmp		$+5
			jmp		label
			endm
;===============================================================================
_cjne		macro	_A,_B,Label
			local	Label_1,Label_2
			cjne	_A,#_B,Label_1
			jmp		Label_2
		Label_1:
		    jmp     Label
		Label_2:
		    endm
;===============================================================================
if	USE_WDT
	if	CPU_TYPE = 52
		_wdtrst	macro
				mov		0A6h,	#1Eh
				mov		0A6h,	#0E1h
				endm
	elseif	CPU_TYPE = 8252
		_wdtrst	macro
				
				endm
	endif
endif
;===============================================================================
_select_dptr	macro	_dptr
				if CPU_TYPE = 52
					if	_dptr = 0
						mov		0A2h,	#11111110b								; select DP0L, DP0H
					elseif _dptr = 1
						mov		0A2h,	#00000001b								; select DP1L, DP1H
					endif
				elseif CPU_TYPE = 8252
					if	_dptr = 0
						anl		WMCON,	#11111011b								; select DP0L, DP0H
					elseif _dptr = 1
						orl		WMCON,	#00000100b								; select DP1L, DP1H
					endif
				endif
				endm
;===============================================================================
_return_val	macro	value
			mov		returned_value,#value
			ret
			endm
;-------------------------------------------------------------------------------
_return_var	macro	value
			mov		returned_value,value
			ret
			endm
;===============================================================================
_jmp_if_z	macro	value,label
			mov		A,		value
			jz		label
			endm
;===============================================================================
_return_if_z	macro	value
				local	label
				mov		A,		value
				jnz		label
				ret
			label:
				endm
;===============================================================================
_check_returned_value	macro	label
						local	Loop_check_returned_value
						mov		returned_value,#0
					label:
						djnz	returned_value,Loop_check_returned_value
						ret
					Loop_check_returned_value:
						endm
;===============================================================================
