;===============================================================================
; hardware_profile.inc
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
if	CPU_TYPE = 1051
END_OF_RAM	equ	63
elseif	CPU_TYPE = 2051
END_OF_RAM	equ	127
else
END_OF_RAM	equ	255
endif
;===============================================================================