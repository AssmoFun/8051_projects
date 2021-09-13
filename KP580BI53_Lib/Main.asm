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
org 03h ; INT0 interrupt
;    jmp HandlerInt0
    reti
org 0Bh ; Timer0 interrupt
    jmp HandlerTimer0
    reti
org 13h ; INT1 interrupt
;    jmp HandlerInt1
    reti
org 1Bh ; Timer1 interrupt
;    jmp HandlerTimer1
    reti
org 23h ; UART interrupt
;    jmp HandlerUart
    reti
org 2Bh ; Timer2 interrupt
;    jmp HandlerTimer2
    reti
;======================================================================================================================================================
org 30h
;======================================================================================================================================================
Init:
    mov  SP,  #stack
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

;    mov  TCON,#00010101b ; Contol Timer0 & Timer1, external interrupts INT0 & INT1
    ;          ||||||||
    ;          |||||||+--- IT0 - Type INT0: 0 - by level, 1 - by falling
    ;          ||||||+---- IE0 - Request INT0 (if IT0=1 automatically clear in heandler)
    ;          |||||+----- IT1 - Type INT1: 0 - by level, 1 - by falling
    ;          ||||+------ IE1 - Request INT1 (if IT1=1 automatically clear in heandler)
    ;          |||+------- TR0 - Start Timer0
    ;          ||+-------- TF0 - Flag overflow Timer0
    ;          |+--------- TR1 - Start Timer0
    ;          +---------- TF1 - Flag overflow Timer1

;    mov  IE,  #10000010b ; Set Interrupts
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
;    clr  KP580BI53_GATE_PIN
    ; init all KP580BI53 channels as PWM
;    _KP580BI53_SET_TIMER CH0,RW_HIGH,PWM,BINARY
;    _KP580BI53_SET_TIMER CH1,RW_HIGH,PWM,BINARY
;    _KP580BI53_SET_TIMER CH2,RW_HIGH,PWM,BINARY
    ; set individual position for every servo
;    _KP580BI53_WRITE_BYTE CH0,#SERVO_MIN_POSITION
;    _KP580BI53_WRITE_BYTE CH1,#SERVO_MEDIUM_POSITION
;    _KP580BI53_WRITE_BYTE CH2,#SERVO_MAX_POSITION

    _KP580BI53_SET_TIMER CH0,RW_HIGH,MEANDER,BINARY ; out of this channel connect to CLK input CH1
    _KP580BI53_SET_TIMER CH1,RW_HIGH,TIMER,BINARY   ; out of this channel connect to GATE input CH2
    _KP580BI53_SET_TIMER CH2,RW_HIGH,MUSIC,BINARY   ; out of this channel connect to BUZZER
     
     _KP580BI53_WRITE_BYTE CH0,#2                   ; set frequency for CH1 (generated MEANDER on CH0)
;     _KP580BI53_WRITE_BYTE CH2,#do1
;======================================================================================================================================================
Main:
;    _KP580BI53_WRITE_BYTE CH1,#1
;    call Delay
;    jmp  Main

    mov  DPTR,#Song
Play_Music:
    clr  A
    movc A,@A+DPTR                                  ; get note frequency
    jz   Main
    _KP580BI53_WRITE_BYTE_FROM_ACC CH2              ; load note lenght frequency
;    dec  A
;    jnz  Skip_Off_Buzzzer
;    clr  KP580BI53_GATE_2_PIN
;Skip_Off_Buzzzer:
    inc  DPTR                                       ; select note lenght
    clr  A
    movc A,@A+DPTR                                  ; get note lenght
    mov  B,A
    mov  A,#16
    div  AB                                         ; get count of 1/16 sec lenght
    _KP580BI53_WRITE_BYTE_FROM_ACC CH1              ; load note lenght
Sound:
    _KP580BI53_SET_TIMER CH1,COUNT_LATCH,TIMER,BINARY
    _KP580BI53_READ_BYTE CH1
    jnz  Sound
    inc  DPTR                                       ; get next note
;    setb KP580BI53_GATE_2_PIN

;    clr  KP580BI53_GATE_PIN
;    call Delay
;    setb KP580BI53_GATE_PIN

    jmp  Play_Music
;======================================================================================================================================================
Delay:
    mov  R2,#1
Loop_Delay:
    djnz R0,$
    djnz R1,Loop_Delay
    djnz R2,Loop_Delay
    ret
;======================================================================================================================================================
HandlerTimer0:
    clr  TF0
    ; every 20ms (f=50Hz)
    mov  TL0,#low(not(20000))
    mov  TH0,#high(not(20000))
    ; start PWM on all KP580BI53 channels
    _KP580BI53_STROB KP580BI53_GATE_PIN
    reti
;======================================================================================================================================================
Song:
;    db      do1,2,si2,2,0

	db      mi2,4,mi2,4,mi2,2,mi2,4
	db      mi2,4,mi2,2,mi2,4,sol2,4
	db      do2,4,re2,4,mi2,1,fa2,4
	db      fa2,4,fa2,4,fa2,4,fa2,4
	db      mi2,4,mi2,4,mi2,4,mi2,4
	db      re2,4,re2,4,mi2,4,re2,2
	db      sol2,2
	db      mi2,4,mi2,4,mi2,2,mi2,4
	db      mi2,4,mi2,2,mi2,4,sol2,4
	db      do2,4,re2,4,mi2,1,fa2,4
	db      fa2,4,fa2,4,fa2,4,fa2,4
	db      mi2,4,mi2,4,mi2,4,sol2,4
	db      fa2,4,mi2,4,re2,4,do2,1
	db      0
;======================================================================================================================================================
end
