;======================================================================================================================================================
F_CPU set 11059 ; kHz
;F_CPU set 12000 ; kHz
;F_CPU set 22118 ; kHz
;F_CPU set 24000 ; kHz

if F_CPU > 19199
F_CPU set 19199 ; kHz. Warning !!! F_CPU is too much for KP580BB79. Set max F_CPU value to 19199
endif

USE_KP580BB79_CS set 0
if USE_KP580BB79_CS
KP580BB79_CS_PIN bit P2.0
endif

KP580BB79_A0_PIN          bit P3.4
KP580BB79_IRQ_PIN         set INT1
KP580BB79_SYMBOLS         set 8
INIT_KP580BB79_IRQ_IN_LIB set 1
USE_KP580BB79_INIT_DELAY  set 1
;======================================================================================================================================================
_read_data_KP580BB79 macro
                     if USE_KP580BB79_CS
                         clr   KP580BB79_CS_PIN
                     endif
                     movx A,@R0
                     if USE_KP580BB79_CS
                         setb KP580BB79_CS_PIN
                     endif
                     endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_write_data_KP580BB79 macro
                      if USE_KP580BB79_CS
                          clr   KP580BB79_CS_PIN
                      endif
                      movx @R0,A
                      if USE_KP580BB79_CS
                          setb KP580BB79_CS_PIN
                      endif
                      endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
_write_command_KP580BB79 macro command
                         mov  A,command
                         call Write_command_KP580BB79
                         endm
;======================================================================================================================================================
;                 000DDKKS
INIT_DISP_KEY equ 00000000b ; Control word init display & keyboard
;                    |||||
;                    ||||+--- S  - 0  - scan as 4-bit bin counter, 1 - scan as inverse decoder on 4 digit
;                    ||++---- KK - 00 - single press, 01 - N-num press, 10 - scan sensors matrix, 11 - mode strob input
;                    ++------ DD - 00 - 8 symbols input left, 01 - 16 symbols input left, 10 - 8 symbols input right, 11 - 16 symbols input right

LEFT_INPUT_SYMB_8   set 00000b
LEFT_INPUT_SYMB_16  set 01000b
RIGHT_INPUT_SYMB_8  set 10000b
RIGHT_INPUT_SYMB_16 set 11000b

ONE_PRESS           set   000b
N_KEY_PRESS         set   010b
SCAN_MATRIX         set   100b
STROB_INPUT         set   110b

BIN_COUNTER         set     0b
INVERSE_DESHIFRATOR set     1b

_init_KP580BB79 macro DD,KK,S
                mov  A,#INIT_DISP_KEY+DD+KK+S
                call Init_KP580BB79
                endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
DIV_KP580BB79  set (F_CPU/6)/100
if DIV_KP580BB79 > 31
DIV_KP580BB79  set 31 ; Warning !!! F_CPU is too much for KP580BB79. Diver will be setting to max value 11111b
endif
;                  001PPPPP ; ALE=Fcpu/6, F_KP580BB79 = ALE/–––––
FREQ_KP580BB79 set 00100000b | DIV_KP580BB79 ; default value 11111b (31 in dec, 1Fh in hex)
;======================================================================================================================================================
INC_OFF        set 00000b
INC_ON         set 10000b
;======================================================================================================================================================
;                010IXAAA
READ_KEY_MEM equ 01000000b
;                   | |||
;                   | +++----- AAA - address
;                   +--------- I   - autoincrement, 0 - autoincrement off, 1 - autoincrement on

_before_read_key_KP580BB79 macro I,POS
                           mov  A,#READ_KEY_MEM+I+POS
                           call	Write_command_KP580BB79
                           endm

_read_key_KP580BB79 macro POS
                    _before_read_key_KP580BB79  INC_ON,POS
                    movx A,@R0
                    endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
;                 011IAAAA
READ_DISP_MEM equ 01100000b
;                    |||||
;                    |++++--- ¿¿¿¿ - display pointer
;                    +------- I    - autoincrement, 0 - autoincrement off, 1 - autoincrement on

_before_read_display_KP580BB79 macro I,POS
                               mov  A,#READ_DISP_MEM+I+POS
                               call	Write_command_KP580BB79
                               endm

_read_display_KP580BB79 macro POS
                        _before_read_display_KP580BB79    INC_ON,POS
                        movx A,@R0
                        endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
;                  100IAAAA
WRITE_DISP_MEM equ 10000000b
;                     |||||
;                     |++++--- ¿¿¿¿ - display pointer
;                     +------- I    - autoincrement, 0 - autoincrement off, 1 - autoincrement on

_before_write_display_KP580BB79 macro I,POS
                                mov  A,#WRITE_DISP_MEM+I+POS
                                call Write_command_KP580BB79
                                endm

_write_display_KP580BB79 macro POS
                         _before_write_display_KP580BB79  INC_ON,POS
                         movx @R0,A
                         endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
BLANK_DISP_MEM equ 10100000b ; 101X.IWA.IWB.BLA.BLB
;                      ||||
;                      |||+--- BLB - blank tetrad ¬
;                      ||+---- BLA - blank tetrad ¿
;                      |+----- IWB - ban tetrad ¬
;                      +------ IWA - ban tetrad ¿

IWA_OFF set 0000b
IWA_ON  set 1000b

IWB_OFF set  000b
IWB_ON  set  100b

BLA_OFF set   00b
BLA_ON  set   10b

BLB_OFF set    0b
BLB_ON  set    1b

_blank_display_KP580BB79 macro IWA,IWB,BLA,BLB
                         mov  A,#BLANK_DISP_MEM+IWA+IWB+BLA+BLB
                         call Write_command_KP580BB79
                         endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
CLEAR_DISP_MEM equ 11000000b ; 110.CD.BC.BC.CF.CA
;                     |||||
;                     ||||+--- CA - work as CD & CF + reset internal synchonizationË
;                     |||+---- CF - clear state byte, interrupt signal, set pointer memory sensors matrix on string 0
;                     |++----- BC - blanc code ÍÓ‰˚ ·Î‡ÌÍËÓ‚ÌËˇ: 00 - 00h (default value), 10 - 20h (space), 11 - 0FFh
;                     +------- CD - reset display memory by filling blanc code (160 ÏÍÒ). Display memory unavailable in this time (high bit of state byte is set)

CD_OFF   set 00000b
CD_ON    set 10000b

BC_ZERO  set  0000b
BC_BLANK set  1000b
BC_ONE   set  1100b

CF_OFF   set    00b
CF_ON    set    10b

CA_OFF   set     0b
CA_ON    set     1b

_clear_display_KP580BB79 macro CD,BC,CF,CA
                         mov  A,#CLEAR_DISP_MEM+CD+BC+CF+CA
                         call Write_command_KP580BB79
                         endm
;------------------------------------------------------------------------------------------------------------------------------------------------------
;             111EXXXX
RESET_INT equ 11100000b ; reset interrupt/error. In KK = 10 (scan sensors matrix), will be reset interrupt & allows writing to keyboard memory
;                |
;                +------- E - in KK = 01 (N-num press), by setting this bit controller set error mode
;======================================================================================================================================================
