;======================================================================================================================================================
include 'KP580BB55_extern.inc'
;======================================================================================================================================================
Main_idata segment idata
rseg Main_idata
stack:
;======================================================================================================================================================
Main_code segment code
rseg Main_code
;======================================================================================================================================================
cseg at 0h
    jmp Init
org 03h                                                                         ; INT0 interrupt
;    jmp INT0
    reti
org 0Bh                                                                         ; Timer0 interrupt
;    jmp Timer0
    reti
org 13h                                                                         ; INT1 interrupt
;    jmp INT1
    reti
org 1Bh                                                                         ; Timer1 interrupt
;    jmp Timer1
    reti
org 23h                                                                         ; UART interrupt
;    jmp Serial_Int
    reti
org 2Bh                                                                         ; Timer2 interrupt
    reti
;======================================================================================================================================================
org	30h
;======================================================================================================================================================
Init:
    mov  SP,#stack
;======================================================================================================================================================
;== Set Timers & Interrupts ===========================================================================================================================
;======================================================================================================================================================
;    mov  TMOD,#00000001b ; Mode Timer0 & Timer1
    ;          ||||||||
    ;          ||||||++--- Mode Timer0 (01 - 16-bit, 10 - 8-bit & reload, 11 - 2 independent 8-bit)
    ;          |||||+----- C/T0: 0 - timer, 1 - counter
    ;          ||||+------ Gate_T0: 0 - control by TR0, 1 - control by TR0 & INT0
    ;          ||++------- Mode Timer1 (01 - 16-bit, 10 - 8-bit & reload, 11 - illegal)
    ;          |+--------- C/T1: 0 - timer, 1 - counter
    ;          +---------- Gate_T1: 0 - control by TR1, 1 - control by TR1 & INT1

;    mov  TCON,#00000101b ; Contol Timer0 & Timer1, external interrupts INT0 & INT1
    ;          ||||||||
    ;          |||||||+--- IT0 - Type INT0: 0 - by level, 1 - by falling
    ;          ||||||+---- IE0 - Request INT0 (if IT0=1 automatically clear in heandler)
    ;          |||||+----- IT1 - Type INT1: 0 - by level, 1 - by falling
    ;          ||||+------ IE1 - Request INT1 (if IT1=1 automatically clear in heandler)
    ;          |||+------- TR0 - Start Timer0
    ;          ||+-------- TF0 - Flag overflow Timer0
    ;          |+--------- TR1 - Start Timer0
    ;          +---------- TF1 - Flag overflow Timer1

;    mov  IE,  #10000000b ; Set Interrupts
    ;          ||||||||
    ;          |||||||+--- EX0 - enable INT0 interrupt
    ;          ||||||+---- ET0 - enable Timer0 interrupt
    ;          |||||+----- EX1 - enable INT1 interrupt
    ;          ||||+------ ET1 - enable Timer1 interrupt
    ;          |||+------- ES  - enable UART interrupt
    ;          ||+-------- ET2 - enable Timer2 interrupt
    ;          |+--------- Reserv, not used
    ;          +---------- EA  - enable all not masked interrupts
;======================================================================================================================================================
    _init_KP580BB55       PortA_output,PortB_output,PortC_4_7_output,PortC_0_3_output
    _init_KP580BB55_Port  PortA_intput ; Reinit PortA as input
;------------------------------------------------------------------------------------------------------------------------------------------------------
    _KP580BB55_write_byte PortC,#00001111b
    _set_PortC_bit        bit_0,0
    _set_PortC_bit        bit_1,0
    _set_PortC_bit        bit_6,1
    _set_PortC_bit        bit_7,1
;======================================================================================================================================================
Main:
    _KP580BB55_read_byte    PortA
    _KP580BB55_write_from_A	PortB
    jmp  Main
;======================================================================================================================================================
end