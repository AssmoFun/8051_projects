;===============================================================================
; xy_mk_5v_inc.inc - xy_mk_5v include file. Need xy_mk_5v_lib.asm & xy_mk_5v_extern.inc to use
;===============================================================================
; Option ¹1 - the data bit is encoded with a high level length
; Connect the output of the receiver directly to P3.2 (INT0), or P3.3 (INT1)

; WARNING !!! When the level is maintained for more than 100 ms, the reception is interrupted. You need to change the level at least once every 100 ms
; Pulses shorter than 200 ?s pass poorly through the receiver path. The optimal timing for this set is 350-1000 ?s
; For pulses of 50-100 ?s, the receivers are an order of magnitude more expensive, and this is usually a superheterodyne
; Regarding the change of pulse durations after the passage of the path - the question is very big and in 2 words you can not describe it
; This is due to the frequency response of the analog path, which has a blockage at the high edge of the range
; There is a simple empirical rule: after passing the path, the short pulse shortens, the long one lengthens.
; On this receiver, the high level shortens and the low level lengthens
; The receiver comes to readiness in 40-50 ms after the beginning of a packet, and duration of a pause between packets can be 100ms
; You can use a single trick to speed up the adaptation of the receiver. At the beginning of the packet is transmitted a long pulse of the carrier 3-4ms,
; then the pilot is transmitted with 15-20 short pulses, then the sync pulse, and then the data
; Each millisecond of carrier is equivalent in energy to 2 milliseconds of the code that gives the chance to reduce readiness time twice

; Theory:
; Ideally, the receiver and transmitter (if both on the MCS-51) should operate on the same quartz (because all time constraints are tied to Timer0 ticks)
; Due to the use of bit synchronization, the use of quartz close to the nominal value is allowed (for example, 12 MHz for the transmitter, and 11.0592 MHz for the receiver, or vice versa)
; A preamble with synchrobit is definitely required. Preamble for the receiver to enter the operating mode. The synchrobit must be different in duration from the data bit (0 and 1),
; so that if the receiver misses the start of the transmission at some point, it does not start receiving data from the middle of the packet, but waits for the start of a new transmission
; Thus, synchronization makes it possible to synchronize, ie to determine the beginning of the transmission of information data

; Parameters:
; All time limits are specified for 12MHz quartz, but this does not matter much, as everything is tied to the Timer0 ticks. You can take any quartz, at least at 24MHz, and then the time limit will be reduced by 2 times. Just then the transmitter will also have to take quartz with a close denomination
; 0 is encoded by a high level lasting from 100h to 1FFh of Timer0. For 12 MHz it is from 256us to 511us (with an ideal transmitter - 384us)
; 1 is encoded with a high level lasting from 200h to 2FFh Timer0. For 12 MHz it is from 512us to 767us (with an ideal transmitter - 640us)
; The preamble bit is encoded at a high level lasting from 300h to 3FFh Timer0. For 12 MHz it is from 768us to 1023us (with an ideal transmitter - 900us)
; Any high level (preamble bit, synchrobit, or data bit) is always followed by a low level, lasting from 100h to 1FFh of Timer0 ticks. For 12 MHz it is from 256us to 511us (with an ideal transmitter - 384us)
; Anything that does not fit into these intervals is a reception error
; The data bit before receiving the sync is ignored
; Sudden pulse with preamble bit length (or synchrobit) during data reception - reception error
; Any reception error puts the receiver in the initial state - waiting for synchrobit (the next high level with a duration in the range from 300h to 3FFh ticks Timer0)

; Procedure:
; When you turn on the receiver:
; Set up 2 interrupts: INT0 (or INT1), and overflow Timer0. Entering the interrupt handler Timer0 - reception error (stop Timer0, prohibition of external interrupt on the receiver leg). This will automatically eliminate any time that is too long
; Start Timer0 to fix the value of the preamble (TL0 = 0, TH0 = 0FCh), start the counter for 8 bits of data, wait for the beginning of a high level
; As soon as the high level is fixed - we start Timer0, we allow external interruption INT0 (INT1), and we pass to waiting in the main cycle

; In the main cycle:
; As soon as the radio gives a low level - the interrupt handler INT0 (INT1) is called
; Reset TL0 to 0. This gives us 255 cycles to overwrite TH0. This is enough for the longest version of the processor

; Analyze the end bit of the preamble. If reset - preamble bit processing. If set - data bit proc;essing

; Preamble bit processing
; We look at the value of TH0. If TH0! = 0FFh - reception error
; Otherwise - the correct length of the preamble bit - set the end of the preamble reception bit
; We turn to the common for all handler low-level receiver

; Data bit processing
; We look at the value of TH0. If TH0 = 0FEh is log.0, if TH0 = 0FFh is log.1 (This can be checked by a tricky construction: subtract the current TH0 from 0FEh. Log.1 will set the carry flag, log.0 will set the flag to zero. The signal is NOT too short set too long. Too long signal will be eliminated even earlier, interrupt on overflow Timer0)
; Push the received bit into the data byte (via ACC), the decrement of the data bit counter. If it became 0 - re-start the counter for 8 bits of data

; We look at value of the counter of the accepted bytes. If 0, then we accept the 1st byte of the packet - the amount of data, otherwise we take the next byte of data, or checksum (the last byte of the packet, not written to the receiving buffer)

; Receiving a byte of the amount of data
; Get the newly received byte in the ACC, and take as a basis checksum, copy the value from the ACC to the counter of received bytes, and after the decrement, in the variable amount of data
; We pass to the general for all handler of a low level of the receiver

; Receiving the next byte of data, or checksum
; We get the byte just received in ACC
; Decrement of the counter of the accepted bytes. If it became 0 - the end of the reception. We compare the accepted and counted checksum, if it coincided, we expose a bit of the end of reception. Otherwise reception error
; If it did not become 0, we make exclusive OR (xrl) of the accepted byte with current checksum, we write the accepted byte in the buffer, we increment the pointer to the buffer
; We pass to the general for all handler of a low level of the receiver

; Common to all low-level receiver handler
; We start Timer0 to fix the end of the low level (TH0 = 0FEh), in TL0 something has already flowed, but without overflow, so there is still time
; Awaiting low end with Timer0 overflow control:
; jb TF0, Receive_Error
; jnb xy_mk_5v_pin, $ - 3
; At the end we look at the value of TH0. If TH0! = 0FFh, reception error
; Otherwise we continue reception, we start Timer0 on fixing of a bit of data (TL0 = 0, TH0 = 0FDh)

; Package structure:
; 1. 1 long pulse of the preamble
; 2. 16-20 short pulses of the preamble
; 3. 1 sync pulse
; 4. First byte - LEN (LEN> = 2 && LEN <= BUFF_SIZE + 1) DATA + CHECKSUM
; 5. The next bytes are DATA
; 6. The last byte - CHECKSUM (LEN + XOR all DATA bytes)
;===============================================================================
XY_MK_5V_IRQ			equ	INT1
USE_PSW_BITS			equ	1													; 0 - max XY_MK_5V_BUFF_SIZE for AT89C1051 = 31, 1 - max XY_MK_5V_BUFF_SIZE for AT89C1051 = 48 (Stack = 6 bytes)
XY_MK_5V_BUFFSIZE		equ	48

if	USE_PSW_BITS = 1
xy_mk_5v_preamb_ok		bit PSW.1
xy_mk_5v_receive_compl	bit F0		; PSW.5
endif

if	XY_MK_5V_IRQ = INT0
xy_mk_5v_pin			bit	P3.2
elseif	XY_MK_5V_IRQ = INT1
xy_mk_5v_pin			bit	P3.3
else
ERROR
endif

TH0_PREAMB				equ	0FFh-3	; 0FCh
TH0_DATA				equ	0FFh-2	; 0FDh
TH0_LOW_LVL				equ	0FFh-1	; 0FEh
XY_MK_5V_BITNUM			equ	8

_stop_xy_mk_5v	macro
				clr		TR0														; stop Timer0
			if	XY_MK_5V_IRQ = INT0
				clr		EX0														; disable XY_MK_5V_IRQ
			elseif	XY_MK_5V_IRQ = INT1
				clr		EX1														; disable XY_MK_5V_IRQ
			else
				ERROR
			endif
				endm
