;Author: Jack (z5129432)
;Date: 15/08/2017
;Version: 1
;Description: 
; Test sample:
; initialization: dividend =  0b1100 1001 0001 = 0x0C91
;                 divisor  = 0b0001 0000 = 0x0010
;                 bit_positon = 0b0001 = 0x0001
;                 quotient = 0b0000 = 0x0000
;
; iteration 1:    divisor << 3 = 0b1000 0000 0000 = 0x0800
;	              bit_position = 0b1000 0000 = 0x0080
;
; iteration 2:	  bit_position > 0
;                 dividend = dividend - divisor = 0100 1001 0001 = 0x0491
;                 quotient = quotient + bit_position = 0b1000 0000 = 0x0080
; iteration 3:    divisor >> 1 = 0b0100 0000 0000 = 0x0400
;                 bit_position >> 1 = 0b0100 0000 = 0x0040
; iteration 2:    dividend = dividend - divisor = 1001 0001 = 0x0091
;                 quotient = quotient + bit_position = 0b1100 0000 = 0x00C0
; iteration 3:    divisor >> 3 = 0b1000 0000 = 0x0080
;                 bit_position >> 1 = 0b1000 = 0x0008
; iteration 2:    dividend = dividend - divisor = 0001 0001 = 0x0011
;                 quotient = quotient + bit_position = 0b1100 1000 = 0x00C8
; iteration 3:    divisor >> 3 = 0b0001 0000 = 0x0010
;                 bit_position >> 1 = 0b0001 = 0x0001
; iteration 2:    dividend = dividend - divisor = 0b0001 = 0x0001
;                 quotient = quotient + bit_position = 0b1100 1001 = 0x00C9
; write_result:   because bit_positon = 0, then end
;                 expected quotient = 0b1100 1001 = 0x00C9

.include "m2560def.inc"
.def zero = R15     ; zero value
.def dividend_H = R16
.def dividend_L = R17
.def divisor_H = R18
.def divisor_L = R19
.def quotient_H = R20
.def quotient_L = R21
.def bit_position_H = R22
.def bit_position_L = R23

; code/program memory, constants, starts from 0x0000
                 .cseg                       
dividend:        dw 0x0C91
divisor:         dw 0x0010

 ; data memory, variables, starts form 0x0020
                 .dseg                      
                 .org 0x0200
quotient:        .byte 2  ; two byte quotient variable, little endian rule is used


; initialization
                clr zero

                ldi ZH, high(dividend << 1)     ; load dividend to registers
                ldi ZL, low(dividend << 1)
                lpm dividend_H, Z+
                lpm dividend_L, Z

                ldi ZH, high(divisor << 1)      ; load divisor to registers
                ldi ZL, low(divisor << 1)
                lpm divisor_H, Z+
                lpm divisor_L, Z

                ldi bit_position_H = 0x00        ; initialise bit_positon = 0x0001
                ldi bit_position_L = 0x01
                clr quotient_H                   ; initialise quotient = 0x0001
                clr quotient_L

iteration_1:    cpi divisor_H, 0x80              ; if divisor_H >= 0b1000 0000
                brsh iteration_2                        ; branch is same of higher
                cp divisor_H, dividend_H        ; if divisor >= divident
                cpc divisor_L, dividend_L
                brsh iteration_2

                lsl divisor_L                   ; left shift one
                rol divisor_H                   ; left shift one with carry
                lsl bit_position_L              ; left shift one
                rol bit_position_H              ; left shift one with carry
                rjmp iteration_1

iteration_2:    cp bit_position_L, zero        ; if bit_positon = 0, jump to next iteration
                cpc bit_position_H, zero 
                breq write_result

                cp dividend_L, divisor_L        ; if dividend < divisor, jump to next iteration
                cpc dividend_H, divisor_H
                brlo iteration_3                ; branch is lower

                sub dividend_L, divisor_L       ; dividend = dividend - divisor
                sbc dividend_H, divisor_H
                add quotient_L, bit_position_L  ; quotient = quotient + bit_positon
                adc quotient_H, bit_position_H

iteration_3:    lsr divisor_H                   ; right shift divisor
                ror divisor_L
                lsr bit_position_H              ; right shift bit_position
                lsr bit_position_L
                rjmp iteration_2

write_result:   ldi ZH, high(quotient << 1)     ; load quotient to registers
                ldi ZL, low(quotient << 1)
                st Z+, quotient_H
                st Z, quotient_L

end:            rjmp end