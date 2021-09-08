;======================================================================================================================================================
include 'KP580BI53_extern.inc'
;======================================================================================================================================================
SERVO_MIN_POSITION    set 5
SERVO_MEDIUM_POSITION set 12
SERVO_MAX_POSITION    set 20
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

    clr  TF0
    ; every 20ms (f=50Hz)
    mov  TL0,#low(65535-20000)
    mov  TH0,#high(65535-20000)
    ; start PWM on all KP580BI53 channels
    _KP580BI53_STROB KP580BI53_GATE_PIN

    reti
;org 13h                                                                         ; INT1 interrupt
;    jmp INT1
;    reti
org 1Bh                                                                         ; Timer1 interrupt
;    jmp Timer1
    reti
org 23h                                                                         ; UART interrupt
;    jmp Serial_Int
    reti
org 2Bh                                                                         ; Timer2 interrupt
    reti
;======================================================================================================================================================
org 30h
;======================================================================================================================================================
Init:
    mov  SP,#stack
;======================================================================================================================================================
;== Set Timers & Interrupts ===========================================================================================================================
;======================================================================================================================================================
    mov  TMOD,#00000001b ; Mode Timer0 & Timer1
    ;          ||||||||
    ;          ||||||++--- Mode Timer0 (01 - 16-bit, 10 - 8-bit & reload, 11 - 2 independent 8-bit)
    ;          |||||+----- C/T0: 0 - timer, 1 - counter
    ;          ||||+------ Gate_T0: 0 - control by TR0, 1 - control by TR0 & INT0
    ;          ||++------- Mode Timer1 (01 - 16-bit, 10 - 8-bit & reload, 11 - illegal)
    ;          |+--------- C/T1: 0 - timer, 1 - counter
    ;          +---------- Gate_T1: 0 - control by TR1, 1 - control by TR1 & INT1

    mov  TCON,#00010101b ; Contol Timer0 & Timer1, external interrupts INT0 & INT1
    ;          ||||||||
    ;          |||||||+--- IT0 - Type INT0: 0 - by level, 1 - by falling
    ;          ||||||+---- IE0 - Request INT0 (if IT0=1 automatically clear in heandler)
    ;          |||||+----- IT1 - Type INT1: 0 - by level, 1 - by falling
    ;          ||||+------ IE1 - Request INT1 (if IT1=1 automatically clear in heandler)
    ;          |||+------- TR0 - Start Timer0
    ;          ||+-------- TF0 - Flag overflow Timer0
    ;          |+--------- TR1 - Start Timer0
    ;          +---------- TF1 - Flag overflow Timer1

    mov  IE,  #10000010b ; Set Interrupts
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
    ; disable gate before set timers
    clr  KP580BI53_GATE_PIN
    ; init all KP580BI53 channels as PWM
    _KP580BI53_SET_TIMER CH0,RW_HIGH,PWM,BINARY
    _KP580BI53_SET_TIMER CH1,RW_HIGH,PWM,BINARY
    _KP580BI53_SET_TIMER CH2,RW_HIGH,PWM,BINARY
    ; set individual position for every servo
    _KP580BI53_WRITE_BYTE CH0,#SERVO_MIN_POSITION
    _KP580BI53_WRITE_BYTE CH1,#SERVO_MEDIUM_POSITION
    _KP580BI53_WRITE_BYTE CH2,#SERVO_MAX_POSITION
;======================================================================================================================================================
Main:
    jmp  Main
;======================================================================================================================================================
end
