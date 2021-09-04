;======================================================================================================================================================
;F_CPU set 11059 ; kHz
F_CPU set 12000 ; kHz
;F_CPU set 22118 ; kHz
;F_CPU set 24000 ; kHz

USE_KP580BB55_CS set 0
if USE_KP580BB55_CS
KP580BB55_CS_PIN bit P2.0
endif
KP580BB55_A0_PIN bit P1.3
KP580BB55_A1_PIN bit P1.2

USE_KP580BB55_INIT_DELAY set 1

PortA set 0
PortB set 1
PortC set 2
CWR   set 3 ; (Control Word Register, only write)
;======================================================================================================================================================
;   À1  À0  Port
;   0   0   À
;   0   1   Â
;   1   0   Ñ
;   1   1   CWR (Control Word Register, only write)

;   Control Word Register (CWR, only write)
;   D7 D6 D5 D4 D3 D2 D1 D0
;   |  |  |  |  |  |  |  |
;   |  |  |  |  |  |  |  +-- PÑ0-PC3 (0 - output, 1 - input)
;   |  |  |  |  |  |  +----- PÂ0-PÂ7 (0 - output, 1 - input)
;   |  |  |  |  |  +-------- Mode PÂ0-PÂ7 & PÑ0-PC3 (0 - Mode0, 1 - Mode1)
;   |  |  |  |  +----------- PÑ4-PC7 (0 - output, 1 - input)
;   |  |  |  +-------------- PÀ0-PÀ7 (0 - output, 1 - input)
;   |  +  + ---------------- Mode PÀ0-PÀ7 & PÑ4-PC7 (00 - Mode0, 01 - Mode1, 10 - Mode2)
;   +----------------------- Mode set flag (1 - Mode set, 0 - set/clear PortC bits). If 0, D3-D1 - bit number PÑ, D0 - bit value

SET_MODE         set 10000000b

PortA_output     set    00000b
PortC_4_7_output set     0000b
PortB_output     set       00b
PortC_0_3_output set        0b

PortA_intput     set    10000b
PortC_4_7_intput set     1000b
PortB_intput     set       10b
PortC_0_3_intput set        1b

SET_PORTC_BIT    set 00000000b
bit_0            set     0000b
bit_1            set     0010b
bit_2            set     0100b
bit_3            set     0110b
bit_4            set     1000b
bit_5            set     1010b
bit_6            set     1100b
bit_7            set     1110b
;======================================================================================================================================================
_KP580BB55_read_byte    macro dest
                        if dest = PortA
                            clr  KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortB
                            setb KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortC
                            clr  KP580BB55_A0_PIN
                            setb KP580BB55_A1_PIN
                        else
                            #error
                        endif
                        call Read_KP580BB55
                        endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_KP580BB55_write_byte   macro dest,byte
                        if dest = PortA
                            clr  KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortB
                            setb KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortC
                            clr  KP580BB55_A0_PIN
                            setb KP580BB55_A1_PIN
                        elseif dest = CWR ; only for write operation !!!
                            setb KP580BB55_A0_PIN
                            setb KP580BB55_A1_PIN
                        else
                            #error
                        endif
                        mov  A,byte
                        call Write_KP580BB55
                        endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_KP580BB55_write_from_A macro dest
                        if dest = PortA
                            clr  KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortB
                            setb KP580BB55_A0_PIN
                            clr  KP580BB55_A1_PIN
                        elseif dest = PortC
                            clr  KP580BB55_A0_PIN
                            setb KP580BB55_A1_PIN
                        elseif dest = CWR ; only for write operation !!!
                            setb KP580BB55_A0_PIN
                            setb KP580BB55_A1_PIN
                        else
                            #error
                        endif
                        call Write_KP580BB55
                        endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_init_KP580BB55 macro PA_mode,PB_mode,PC_high_mode,PC_low_mode
                if USE_KP580BB55_INIT_DELAY
                    push 0h
                    push 1h
                    mov  1h,#(F_CPU/800)
                Loop_delay_init_KP580BB55:
                    djnz 0h,$
                    djnz 01,Loop_delay_init_KP580BB55
                    pop  1h
                    pop  0h
                endif
                _KP580BB55_write_byte CWR,#SET_MODE+PA_mode+PB_mode+PC_high_mode+PC_low_mode
                endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_init_KP580BB55_Port macro PORT_MODE
                     _KP580BB55_write_byte CWR,#SET_MODE+PORT_MODE
                     endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_set_PortC_bit macro BITS,VALUE ; function supperted only for PortC
               _KP580BB55_write_byte CWR,#SET_PORTC_BIT+BITS+VALUE
               endm
;======================================================================================================================================================
