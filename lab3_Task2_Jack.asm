; Author: Jack Jiang(z5129432)
; Date: 5/09/2017
; Version: 1
; Wiring diagram: 
;           LED:
;           LED0 -- PG2
;           LED1 -- PG3
;           LED2 -- PC0
;           LED3 -- PC1
;           LED4 -- PC2
;           LED5 -- PC3
;           LED6 -- PC4
;           LED7 -- PC5
;           LED8 -- PC6
;           LED9 -- PC7
;           
;           INPUTS:
;           Button PB0 -- PD0 --- Use INT0 to stop the LEDs
;           Button PB1 -- PD1 --- Use to halt/resume the partern
;
.include "m2560def.inc"

.def i_1 = R2	; work with loop_counters
.def i_2 = R3	; work with loop_counters
.def i_3 = R4	; work with loop_counters
.def Configue = R16		; used for input and output
.def Pattern_Low = R17
.def Pattern_High = R18
.def show_loop_counter = R19	
.def loop_counter_1 = R20	; delay loop counter
.def loop_counter_2 = R21	; delay loop counter
.def loop_counter_3 = R22	; delay loop counter
.def zero = R23		; constant 0
.def one = R24		; constant 1

; number of patterns
.equ show_loop_times = 4

; Wait calculation:
; CPU frequency: 16MHz
; Delay time:    1 Sec
; Total clock cycles = 16_000_000
; Unit clock cycle = 13
; Loop times = 16_000_000 / 13 = 1230769
.equ wait_loop_times = 1_230_769

; Delay calculation:
; CPU frequency: 16MHz
; Delay time:    200ms
; Total clock cycles = 16_000_000 * 0.2 = 3_200_000
; Unit clock cycle = 9
; Loop times = 3_200_000 / 9 = 355_555
.equ delay_loop_times = 355_555

; Delay before checking input in order to avoid misbehaviour
.macro bufferDelay

delay_init:
    ldi loop_counter_1, low(delay_loop_times)
    ldi loop_counter_2, high(delay_loop_times)
    ldi loop_counter_3, byte3(delay_loop_times)
    clr i_1
    clr i_2
    clr i_3
delay_loop:
; Delay in this block:  
;               instruction     clock cycles
;               ----------------------------
;               add             1
;               adc             1
;               adc             1
;               cp              1
;               cpc             1
;               cpc             1
;               brsh            1(not jump)
;               rjmp            2
;               -------------------
;               overall         13
;
    add i_1, one
    adc i_2, zero
    adc i_3, zero
    cp i_1, loop_counter_1
    cpc i_2, loop_counter_2
    cpc i_3, loop_counter_3
    brsh delay_end
    rjmp delay_loop
delay_end:
.endmacro

rjmp main
.org INT0addr
	rjmp EXT_INT0
.cseg               
patterns:
    ; only the least significant 10 bits are valid
    .db 0b00000000, 0b00011111	;0x001F
    .db 0b00000011, 0b11100000	;0x03E0
    .db 0b00000010, 0b10101010	;0x02AA
    .db 0b00000001, 0b01010101	;0x0155


main:
	; initialize interupt
    ldi Configue, (2<<ISC00)  ; set INT0 as falling edge triggered interupt
    sts EICRA, Configue
    in Configue, EIMSK        ; enalbe INT0
    ori Configue, (1<<INT0)
    out EIMSK, Configue
	sei                       ; enable global interupt flag
    ; initialize constants
    ldi zero, 0
    ldi one, 1
    ; configure the input and output mode of ports
    in Configue, DDRG
    ori Configue, 0b00000011
    out DDRG, Configue  ; set PG0 and PG1 output mode
    ser Configue
    out DDRC, Configue  ; set PC0 ~ PC7 output mode
    in Configue, DDRD
    andi Configue, 0b11111100
    out DDRD, Configue  ; set PD0 and PD1 input mode
    nop
    in Configue, PORTD
    ori Configue, 0b00000011
    out PORTD, Configue ; active pull-up resister of PD0 and PD1

show_init:
    ; reset loop counter, and address pointer
    ldi show_loop_counter, 0
    ldi ZH, high(patterns << 1)
    ldi ZL, low(patterns << 1)

show_loop:
    ; load patterns from program memory
    lpm Pattern_Low, Z+
    lpm Pattern_High, Z+
    ; show pattern in LED0 and LED1
    in Configue, PORTG				; load current port G
    andi Configue, 0b11111100		; set bit 0 and bit 1 equal to 0
    or Configue, Pattern_Low	; set bit 2 and bit 3 from pattern
    out PORTG, Configue				; output to PG0 and PG1
    ; show pattern in LED2 to LED9
    out PORTC, Pattern_High

wait_init:
    ldi loop_counter_1, low(wait_loop_times)
    ldi loop_counter_2, high(wait_loop_times)
    ldi loop_counter_3, byte3(wait_loop_times)
    clr i_1
    clr i_2
    clr i_3

wait_loop:
; Delay in this block:  
;               instruction     clock cycles
;               ----------------------------
;               add             1
;               adc             1
;               adc             1
;               cp              1
;               cpc             1
;               cpc             1
;               brsh            1(not jump)
;               rjmp            2
;               -------------------
;               overall         9
;
    add i_1, one
    adc i_2, zero
    adc i_3, zero
    cp i_1, loop_counter_1
    cpc i_2, loop_counter_2
    cpc i_3, loop_counter_3
    brsh wait_end
    ; when push PD0 or PD1, the bit is clear. Then run next line of code, jump to halt
    ;sbis PIND, 0
    ;rjmp halt
    ;sbis PIND, 1
    ;rjmp halt
    rjmp wait_loop

wait_end:
    inc show_loop_counter
    cpi show_loop_counter, show_loop_times
    brsh show_init
    rjmp show_loop

halt:
    bufferDelay   ; add some buffer before checking next input

check:
	; when push PD0 or PD1, the bit is clear. Then run next line of code, jump to resume
    sbis PIND, 0
    rjmp resume
    sbis PIND, 1
    rjmp resume
    rjmp check

resume:
    bufferDelay   ; add some buffer before checking next input
    rjmp wait_end

EXT_INT0:
    ; show pattern in LED0 and LED1
    in Configue, PORTG				; load current port G
    andi Configue, 0b11111100		; set bit 0 and bit 1 to 0
    out PORTG, Configue				; output to PG0 and PG1
    ; show pattern in LED2 to LED9
    ldi Configue, 0b00000000        ; set all bits to 0
    out PORTC, Configue
    
end: 
    rjmp end

