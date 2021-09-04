;======================================================================================================================================================
include 'KP580BB79_inc.inc'
;======================================================================================================================================================
public KP580BB79_Symbol_Table,Init_KP580BB79,Write_command_KP580BB79,Read_Key_KP580BB79
;======================================================================================================================================================
KP580BB79_Lib_data segment data
rseg KP580BB79_Lib_data
kp580bb79_symbol_counter: ds 1
;======================================================================================================================================================
KP580BB79_Lib_code segment code
rseg KP580BB79_Lib_code
;======================================================================================================================================================
Write_command_KP580BB79:
    setb KP580BB79_A0_PIN
    _write_data_KP580BB79
    clr  KP580BB79_A0_PIN
    ret
;======================================================================================================================================================
Init_KP580BB79:
    if USE_KP580BB79_INIT_DELAY
        push 0h
        mov  0h,#(F_CPU/800)
    Loop_Init_delay_KP580BB79:
        djnz kp580bb79_symbol_counter,$
        djnz 0h,Loop_Init_delay_KP580BB79
        pop  0h
    endif
    mov  kp580bb79_symbol_counter,#KP580BB79_SYMBOLS+1
    if INIT_KP580BB79_IRQ_IN_LIB
        orl  TCON,#00000101b ; Contol Timer0 & Timer1, external interrupts INT0 & INT1
        ;          ||||||||
        ;          |||||||+--- IT0 - Type INT0: 0 - by level, 1 - by falling
        ;          ||||||+---- IE0 - Request INT0 (if IT0=1 automatically clear in heandler)
        ;          |||||+----- IT1 - Type INT1: 0 - by level, 1 - by falling
        ;          ||||+------ IE1 - Request INT1 (if IT1=1 automatically clear in heandler)
        ;          |||+------- TR0 - Start Timer0
        ;          ||+-------- TF0 - Flag overflow Timer0
        ;          |+--------- TR1 - Start Timer0
        ;          +---------- TF1 - Flag overflow Timer1

        if KP580BB79_IRQ_PIN = INT0
            orl  IE,  #10000001b ; Set Interrupts
        elseif KP580BB79_IRQ_PIN = INT1
            orl  IE,  #10000100b ; Set Interrupts
            ;          ||||||||
            ;          |||||||+--- EX0 - enable INT0 interrupt
            ;          ||||||+---- ET0 - enable Timer0 interrupt
            ;          |||||+----- EX1 - enable INT1 interrupt
            ;          ||||+------ ET1 - enable Timer1 interrupt
            ;          |||+------- ES  - enable UART interrupt
            ;          ||+-------- ET2 - enable Timer2 interrupt
            ;          |+--------- Reserv, not used
            ;          +---------- EA  - enable all not masked interrupts
		else
			#error
		endif
    endif
    call Write_command_KP580BB79
    _write_command_KP580BB79 #FREQ_KP580BB79
    _clear_display_KP580BB79 CD_ON,BC_ZERO,CF_OFF,CA_OFF
    ret
;======================================================================================================================================================
Read_Key_KP580BB79:
    push ACC
    djnz kp580bb79_symbol_counter,No_clear_display                              ; check max symbols
    _clear_display_KP580BB79 CD_ON,BC_ZERO,CF_OFF,CA_OFF
    mov  kp580bb79_symbol_counter,#(F_CPU/150)                                  ; delay 160mks after display reset
    djnz kp580bb79_symbol_counter,$                                             ; using symbol counter for delay
    mov  kp580bb79_symbol_counter,#KP580BB79_SYMBOLS                            ; restore symbol counter
No_clear_display:
    _read_data_KP580BB79                                                        ; take keynum
    mov  DPTR,#KP580BB79_Symbol_Table                                           ; search in table
    movc A,@A+DPTR
    _write_data_KP580BB79                                                       ; out to display
    pop  ACC
    reti
;======================================================================================================================================================
KP580BB79_Symbol_Table:
;       hgfedcba
    db #00111111b ; 0
    db #00000110b ; 1
    db #01011011b ; 2
    db #01001111b ; 3
    db #01100110b ; 4
    db #01101101b ; 5
    db #01111101b ; 6
    db #00000111b ; 7
    db #01111111b ; 8
    db #01101111b ; 9
    db #01110111b ; A
    db #01111100b ; b
    db #00111001b ; C
    db #01011110b ; d
    db #01111001b ; E
    db #01110001b ; F
;======================================================================================================================================================
end
;======================================================================================================================================================
