;======================================================================================================================================================
include 'KP580BB55_inc.inc'
;======================================================================================================================================================
extern code (Write_KP580BB55,Read_KP580BB55)
;======================================================================================================================================================
;   Prototypes
;------------------------------------------------------------------------------------------------------------------------------------------------------
;   _init_KP580BB55         PortA_output,PortB_intput,PortC_4_7_output,PortC_0_3_intput ; Init all ports of KP580BB55
;   _init_KP580BB55_Port    PortA_intput                                                ; Reinit PortA as input
;   _KP580BB55_read_byte    PortA                                                       ; Read Ports state to ACC
;   _KP580BB55_write_byte   PortC,#00001111b                                            ; Write 1 byte to Port
;   _KP580BB55_write_from_A PortB                                                       ; Write 1 byte from ACC to Port
;   _set_PortC_bit          bit_0,1                                                     ; set 0 bit of PortC (function supperted only for PortC)
;   _set_PortC_bit          bit_7,0                                                     ; clear 7 bit of PortC (function supperted only for PortC)
;======================================================================================================================================================
