; Author: Jack (z5129432)
; Date: 12/09/2017
; Version: 1
; Hardware diagram:                  
;
;   Keypad:
;   R3(PL4)    1        2       3       A
;   R2(PL5)    4        5       6       B
;   R1(PL6)    7        8       9       C
;   R0(PL7)    *        0       #       D
;           C0(PL3) C1(PL2) C2(PL1) C3(PL0)
;
;           LEDs:
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

.include "m2560def.inc"

.def config=R16
.def key=R17
.def temp=R18
.def a=R19
.def b=R20
.def c=R21
.def delay_1=R22
.def delay_2=R23
.def delay_3=R24

; delay loop times:
; CPU frequency: 16MHz
; Unit clock cycle = 13
.equ overflow_delay = 200_000
.equ clear_result_delay = 1_500_000
.equ key_scan_delay=20


; function declaration
rjmp reset


delay:
    push delay_1
    push delay_2
    push delay_3
    push a
    push b
    push c
    push config
    push temp
    delay_init:
        clr a
        clr b
        clr c
        ldi config, 0
        ldi temp, 1
    delay_loop:
        ; clock cycles in this block:  
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
        add a, temp
        adc b, config
        adc c, config
        cp a, delay_1
        cpc b, delay_2
        cpc c, delay_3
        brsh delay_end
        rjmp delay_loop
    delay_end:
        pop temp
        pop config
        pop c
        pop b
        pop a
        pop delay_3
        pop delay_2
        pop delay_1
        ret


key_scan:
    ; detect key press and stroe in register key
    ;
    push config
    push temp
    push delay_1
    push delay_2
    push delay_3
    ; column loop initialization
    ldi delay_1, low(key_scan_delay)
    ldi delay_2, high(key_scan_delay)
    ldi delay_3, byte3(key_scan_delay)
    scan_loop:
        ; key(row):                                                invalid
        ; 0000 1000 --> 0000 0100 --> 0000 0010 --> 0000 0001 --> 0000 0000 
        ldi key, 0b0000_1000
        col_scan:
            ; Config = not Key = key - 0b1111_1111:                   invalid                           
            ; 1111 0111 --> 0111 1011 --> 0011 1101 --> 0001 1110 --> 0000 1111    
            mov temp, key
			ldi config, 0b1111_1111
            sub config, temp
            STS PORTL, config
            rcall delay
                ldi temp, 0b1000_0000
                    ; temp(column):                                             invalid
                    ; 1000 0000 --> 0100 0000 --> 0010 0000 --> 0001 0000 --> 0000 1000
                row_scan:
                    LDS config, PINL
                    and config, temp    ; mask other bits
                    cpi config, 0      ; zero mean having button pressed
                    breq scan_end
                    ; loop control
                    lsr temp
                    cpi temp, 0b0000_1000
                    brne row_scan
            ; column loop control
            lsr key
            cpi key, 0b0000_0000
            brne col_scan
        rjmp scan_loop
    scan_end:
        rcall no_key_press
        add key, temp
        pop delay_3
        pop delay_2
        pop delay_1
        pop temp
        pop config
        ret


no_key_press:
    ; return when no key is pressed
    ;
    push key
    push config
    push temp
    push delay_1
    push delay_2
    push delay_3
    ; column loop initialization
    ldi delay_1, low(key_scan_delay)
    ldi delay_2, high(key_scan_delay)
    ldi delay_3, byte3(key_scan_delay)
    no_key_press_loop:
        ; key(row):                                                invalid
        ; 0000 1000 --> 0000 0100 --> 0000 0010 --> 0000 0001 --> 0000 0000 
        ldi key, 0b0000_1000
        no_key_press_col_scan:
            ; Config = not Key = key - 0b1111_1111:                   invalid                           
            ; 1111 0111 --> 0111 1011 --> 0011 1101 --> 0001 1110 --> 0000 1111    
            mov temp, key
			ldi config, 0b1111_1111
            sub config, temp
            STS PORTL, config
            rcall delay
                ldi temp, 0b1000_0000
                    ; temp(column):                                             invalid
                    ; 1000 0000 --> 0100 0000 --> 0010 0000 --> 0001 0000 --> 0000 1000
                no_key_press_row_scan:
                    LDS config, PINL
                    and config, temp    ; mask other bits
                    cpi config, 0      ; zero mean having button pressed
                    breq no_key_press_loop
                    ; loop control
                    lsr temp
                    cpi temp, 0b0000_1000
                    brne no_key_press_row_scan
            ; column loop control
            lsr key
            cpi key, 0b0000_0000
            brne no_key_press_col_scan
    no_key_press_return:
        pop delay_3
        pop delay_2
        pop delay_1
        pop temp
        pop config
        pop key
        ret



convert:
    ; convert key
    ;   R3(PL4)    1        2       3       A
    ;   R2(PL5)    4        5       6       B
    ;   R1(PL6)    7        8       9       C
    ;   R0(PL7)    *        0       #       D
    ;           C0(PL3) C1(PL2) C2(PL1) C3(PL0)
    key_11:
    cpi key, 0b0001_0001
    brne key_12
    ldi key, 0x01
    rjmp convert_end
    key_12:
    cpi key, 0b0001_0010
    brne key_13
    ldi key, 0x04
    rjmp convert_end
    key_13:
    cpi key, 0b0001_0100
    brne key_14
    ldi key, 0x07
    rjmp convert_end
    key_14:
    cpi key, 0b0001_1000
    brne key_21
    ldi key, 0x0E       ; symbol *
    rjmp convert_end

    key_21:
    cpi key, 0b0010_0001
    brne key_22
    ldi key, 0x02
    rjmp convert_end
    key_22:
    cpi key, 0b0010_0010
    brne key_23
    ldi key, 0x05
    rjmp convert_end
    key_23:
    cpi key, 0b0010_0100
    brne key_24
    ldi key, 0x08
    rjmp convert_end
    key_24:
    cpi key, 0b0010_1000
    brne key_31
    ldi key, 0x00
    rjmp convert_end

    key_31:
    cpi key, 0b0100_0001
    brne key_32
    ldi key, 0x03
    rjmp convert_end
    key_32:
    cpi key, 0b0100_0010
    brne key_33
    ldi key, 0x06
    rjmp convert_end
    key_33:
    cpi key, 0b0100_0100
    brne key_34
    ldi key, 0x09
    rjmp convert_end
    key_34:
    cpi key, 0b0100_1000
    brne key_41
    ldi key, 0x0F       ; symbol #
    rjmp convert_end

    key_41:
    cpi key, 0b1000_0001
    brne key_42
    ldi key, 0x0A
    rjmp convert_end
    key_42:
    cpi key, 0b1000_0010
    brne key_43
    ldi key, 0x0B
    rjmp convert_end
    key_43:
    cpi key, 0b1000_0100
    brne key_44
    ldi key, 0x0C
    rjmp convert_end
    key_44:
    cpi key, 0b1000_1000
    brne key_err
    ldi key, 0x0D
    rjmp convert_end
    key_err:
    ldi key, 0xFF
    convert_end:
        ret


overflow_warning:
    push config
    push temp
    push delay_1
    push delay_2
    push delay_3
    ldi delay_1, low(overflow_delay)
    ldi delay_2, high(overflow_delay)
    ldi delay_3, byte3(overflow_delay)
    ldi temp, 3
    overflow_warning_loop:
        ser config
        out PORTC, config
        rcall delay
        clr config
        out PORTC, config
        rcall delay
        dec temp
        cpi temp, 0
        breq overflow_warning_end
        rjmp overflow_warning_loop
    overflow_warning_end:
        pop delay_3
        pop delay_2
        pop delay_1
        pop temp
        pop config
        ret

clear_result:
    push config
    push delay_1
    push delay_2
    push delay_3
    ldi delay_1, low(clear_result_delay)
    ldi delay_2, high(clear_result_delay)
    ldi delay_3, byte3(clear_result_delay)
    ; trun on LED and trun off again
    in config, PORTG				; load current port G
    andi config, 0b1111_1100		; set bit 0 and bit 1 equal to 0
    ori config, 0b0000_0011	        ; set bit 0 to one
    out PORTG, config				; output to PG0 and PG1
    ser config
    out PORTC, config
    rcall delay
    in config, PORTG				; load current port G
    andi config, 0b1111_1100		; set bit 0 and bit 1 equal to 0
    ori config, 0b0000_0000	        ; set bit 0 to one
    out PORTG, config				; output to PG0 and PG1
    clr config
    out PORTC, config
    ; end
    pop delay_3
    pop delay_2
    pop delay_1
    pop config
    ret


get_a:
    push config
    push temp
    push key
    ; using PG 1 indicate this is inputing a
    in config, PORTG				; load current port G
    andi config, 0b1111_1100		; set bit 0 and bit 1 equal to 0
    ori config, 0b0000_0010	        ; set bit 0 to one
    out PORTG, config				; output to PG0 and PG1
    get_a_init:
        ldi a, 0x00
        ldi config, 0   ; for constant 0
        ldi temp, 10    ; for constant 10
    get_a_loop:
        rcall key_scan
        rcall convert
        cpi key, 0x0E       ; if input symbol * then return a
        breq get_a_return
        cpi key, 0x0A       ; if input is not a number then key_scan again
        brsh get_a_loop
        mul a, temp   ; R1:R0 = a * 10
        add R0, key         ; R1:R0 = R1:R0 + key
        adc R1, config
        cp R1, config           ; if R1 != 0, then jump to over flow
        brne get_a_overflow
        mov a, R0
        OUT PORTC, a
        rjmp get_a_loop
    get_a_overflow:
        rcall overflow_warning
        rjmp get_a_init
    get_a_return:
        pop key
        pop temp
        pop config
        ret

get_b:
    push config
    push temp
    push key
    ; using PG 1 indicate this is inputing b
    in config, PORTG				; load current port G
    andi config, 0b1111_1100		; set bit 0 and bit 1 equal to 0
    ori config, 0b0000_0001	        ; set bit 0 to one
    out PORTG, config				; output to PG0 and PG1
    get_b_init:
        ldi b, 0x00
        ldi config, 0   ; for constant 0
        ldi temp, 10    ; for constant 10
    get_b_loop:
        rcall key_scan
        rcall convert
        cpi key, 0x0F       ; if input symbol # then return b
        breq get_b_return
        cpi key, 0x0A       ; if input is not a number then key_scan again
        brsh get_b_loop
        mul b, temp   ; R1:R0 = b * 10
        add R0, key         ; R1:R0 = R1:R0 + key
        adc R1, config
        cp R1, config           ; if R1 != 0, then jump to over flow
        brne get_b_overflow
        mov b, R0
        OUT PORTC, b
        rjmp get_b_loop
    get_b_overflow:
        rcall overflow_warning
        rjmp get_b_init
    get_b_return:
        pop key
        pop temp
        pop config
        ret


; program
reset:
    ;  Initialize Port L
    ;  PortL         7   6   5   4   3   2   1   0
    ;  key           R0  R1  R2  R3  C0  C1  C2  C3
    ;  Mode   (input)0   0   0   0   1   1   1   1(output)
    ldi config, 0b00001111
    STS DDRL, config
	; Initialize LEDs
	ser config
    out DDRC, config
    in config, DDRG
    ori config, 0b00000011
    out DDRG, config


main:
    rcall clear_result
    rcall get_a
    rcall get_b
    mul a, b
    ldi config, 0
    cp R1, config           ; if R1 = 0, then show result
    breq show_result
    rcall overflow_warning
    rjmp main
    show_result:            ; if not overflow, show result
        ; using trun off PG0 and PG1 to indicate this is output mode
        in config, PORTG				; load current port G
        andi config, 0b1111_1100		; set bit 0 and bit 1 equal to 0
        ori config, 0b0000_0000	        ; set bit 0 to one
        out PORTG, config				; output to PG0 and PG1
        mov c, R0
        out PORTC, c
        rcall key_scan            ; press any key to continue
    rjmp main

end:
    rjmp end