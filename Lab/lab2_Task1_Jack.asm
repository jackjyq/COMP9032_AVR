;Author: Jack (z5129432)
;Date: 15/08/2017
;Version: 1
;Description: 
; Test sample:
; initialization: dividend =  0b1100 1001 0001 = 0x0C91
;                 divisor  =  0b0000 0001 0000 = 0x0010
;                 bit_positon = 0b0001 = 0x0001
;                 quotient = 0b0000 = 0x0000
; iteration 1:    dividend     = 0b1100 1001 0001 = 0x0C91
; iteration 1:    divisor << 7 = 0b1000 0000 0000 = 0x0800
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
;
; Test Sample 2:
; 0x8000 / 0x0008 = 0x1000

.include "m2560def.inc"

.def dividend_MSB = R16
.def dividend_LSB = R17
.def divisor_MSB = R18
.def divisor_LSB = R19
.def bit_position_MSB = R20
.def bit_position_LSB = R21
.def quotient_MSB = R22
.def quotient_LSB = R23
.def bit_MSB = R24	; constant value 0x00
.def bit_LSB = R25	; constant value 0x00

 ; data memory, variables, starts form 0x0020
                 .dseg                      
                 .org 0x0200
quotient:        .byte 2  ; two byte quotient variable, little endian rule is used

; code/program memory, constants, starts from 0x0000
                 .cseg                       
dividend:        .dw 3000 ; 0x0000 ~ 910C
divisor:         .dw  15; 0x0001 ~ 1000

; initialization
				ldi bit_MSB, 0x00
				ldi bit_LSB, 0x00

                ldi ZH, high(dividend << 1)     ; load dividend to registers
                ldi ZL, low(dividend << 1)
                lpm dividend_LSB, Z+
                lpm dividend_MSB, Z

                ldi ZH, high(divisor << 1)      ; load divisor to registers
                ldi ZL, low(divisor << 1)
                lpm divisor_LSB, Z+
                lpm divisor_MSB, Z

                ldi bit_position_LSB, 0x01        ; initialise bit_positon = 0x0001
                ldi bit_position_MSB, 0x00
                clr quotient_LSB                   ; initialise quotient = 0x0001
                clr quotient_MSB

iteration_1:    ;cpi divisor_MSB, 0x80               ; if divisor_LSB >= 0b1000 0000
				mov XH, divisor_MSB
				mov XL, divisor_LSB
				andi XH, 0x80
				andi XL, 0x00
				or XH, XL
				cpi XH, 0x00
				brne iteration_2
                ;brsh iteration_2                    ; branch is same of higher
                cp divisor_LSB, dividend_LSB        ; if divisor >= divident
                cpc divisor_MSB, dividend_MSB
                brsh redo_left_shift  			  ; branch is same of higher

                lsl divisor_LSB                   ; left shift one
                rol divisor_MSB                   ; left shift one with carry
                lsl bit_position_LSB              ; left shift one
                rol bit_position_MSB              ; left shift one with carry
                rjmp iteration_1

redo_left_shift:lsr divisor_MSB                   ; right shift divisor
                ror divisor_LSB
                lsr bit_position_MSB              ; right shift bit_position
                ror bit_position_LSB

iteration_2:    cp bit_position_MSB, bit_MSB        ; if bit_positon = 1, jump to next iteration
                cpc bit_position_LSB, bit_LSB 
                breq write_result

                cp dividend_LSB, divisor_LSB        ; if dividend < divisor, jump to next iteration
                cpc dividend_MSB, divisor_MSB
                brlo iteration_3                ; branch is lower

                sub dividend_LSB, divisor_LSB       ; dividend = dividend - divisor
                sbc dividend_MSB, divisor_MSB
                add quotient_LSB, bit_position_LSB  ; quotient = quotient + bit_positon
                adc quotient_MSB, bit_position_MSB

iteration_3:    lsr divisor_MSB                   ; right shift divisor
                ror divisor_LSB
                lsr bit_position_MSB              ; right shift bit_position
                ror bit_position_LSB
                rjmp iteration_2

write_result:   ldi YH, high(quotient)     ; load quotient to registers
                ldi YL, low(quotient)
                st Y+, quotient_LSB			; big endian
                st Y, quotient_MSB

end:            rjmp end