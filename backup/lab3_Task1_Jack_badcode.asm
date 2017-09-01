; Author: Jack (z5129432)
; Date: 1/09/2017
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
;           Button PB0 -- PD4
;           Button PB1 -- PD3
;
; Delay calculation:
; CPU frequency: 16MHz
; Delay time:    1 Sec
; clock cycles: 16 000 000
;
; clock cycles out of wait loop:
;               block           clock cycles
;               ----------------------------
;               show_loop       14
;               wait_int        6
;               wait_end        5
;               -------------------
;               overall         25
;
; clock cycles with in wait loop
; overall clock cycles needed = 15999975
; clock cycles in one wait_loop = 13
; wait_loop_time = 15999975 / 13 = 1230767
.include "m2560def.inc"

.def i_1 = R2	; work with wait_loop_counters
.def i_2 = R3	; work with wait_loop_counters
.def i_3 = R4	; work with wait_loop_counters
.def Configue = R16
.def Pattern_Low = R17
.def Pattern_High = R18
.def show_loop_counter = R19
.def wait_loop_counter_1 = R20
.def wait_loop_counter_2 = R21
.def wait_loop_counter_3 = R22
.def zero = R23
.def one = R24

.equ show_loop_times = 4
.equ wait_loop_times = 1230767

; code/program memory, constants, starts from 0x0000
               .cseg
rjmp main                       
patterns:
    ; only the least significant 10 bits are valid
    .db 0b00000000, 0b00011111	;0x001F
    .db 0b00000011, 0b11100000	;0x03E0
    .db 0b00000010, 0b10101010	;0x02AA
    .db 0b00000001, 0b01010101	;0x0155

main:
    ; initialze constants
    ldi zero, 0
    ldi one, 1
    ; configure the input and output mode of ports
    in Configue, DDRG
    ori Configue, 0b00110000
    out DDRG, Configue  ; set PG2 and PG3 output mode
    ser Configue
    out DDRC, Configue  ; set PC0 ~ PC7 output mode
    in Configue, DDRD
    andi Configue, 0b11100111
    out DDRD, Configue  ; set PD3 and PD4 input mode
    nop
    in Configue, PORTD
    ori Configue, 0b00011000
    out PORTD, Configue ; active pull-up resister of PD3 and PD4

show_init:
    ; reset loop counter, and address pointer
    ldi show_loop_counter, show_loop_times - 1
    ldi ZH, high(patterns << 1)
    ldi ZL, low(patterns << 1)

show_loop:
; Delay in this block:  
;               instruction     clock cycles
;               ----------------------------
;               dec             1
;               cpi             1
;               brlo            1(not jump)
;               lpm             3
;               lpm             3
;               in              1
;               andi            1
;               or              1
;               out             1
;               out             1
;               -------------------
;               overall         14
;
    ; load patterns from program memory
    lpm Pattern_Low, Z+
    lpm Pattern_High, Z+
    ; show pattern in LED0 and LED1
    in Configue, PORTG          ; load current port G
    andi Configue, 0b11001111   ; set bit 2 and bit 3 equal to 0
    or Configue, Pattern_Low    ; set bit 2 and bit 3 from pattern
    out PORTG, Configue         ; output to PG2 and PG3
    ; show pattern in LED2 to LED9
    out PORTC, Pattern_High

wait_init:
; Delay in this block:  
;               instruction     clock cycles
;               ----------------------------
;               ldi             1
;               ldi             1
;               ldi             1
;               clr             1
;               clr             1
;               clr             1
;               -------------------
;               overall         6
;
    ldi wait_loop_counter_1, low(wait_loop_times)
    ldi wait_loop_counter_2, high(wait_loop_times)
    ldi wait_loop_counter_3, byte3(wait_loop_times)
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
;               sbic            2
;               rjmp            0(won't excute)
;               sbic            2
;               rjmp            0(won't excute)
;               rjmp            2
;               -------------------
;               overall         
;
    add i_1, one
    adc i_2, zero
    adc i_3, zero
    cp i_1, wait_loop_counter_1
    cpc i_2, wait_loop_counter_2
    cpc i_3, wait_loop_counter_3
    brsh wait_end
    ; when push PD3 or PD4, jump to halt
    ; sbic PIND, 3
    sbis PIND, 3
    rjmp halt
    ; sbic PIND, 4
    sbis PIND, 4
    rjmp halt
    rjmp wait_loop

wait_end:
; Delay in this block:  
;               instruction     clock cycles
;               ----------------------------
;               dec             1
;               cpi             1
;               brlo            1(not jump)
;               rjmp            2    
;               -------------------
;               overall         5
;
    ; loop 'loop_times' times
    dec show_loop_counter
    cpi show_loop_counter, 0
    brlo show_init
    rjmp show_loop

halt:
    sbic PIND, 3
    ; sbis PIND, 3
    rjmp wait_end
    sbic PIND, 4
    ; sbis PIND, 4
    rjmp wait_end
    rjmp halt
    
end: 
    rjmp end