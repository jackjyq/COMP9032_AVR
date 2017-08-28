;Author: Jack (z5129432)
;Date: 28/08/2017
;Version: 1
;Description: String to integer convertor
;Test Sample:
;	input string = "12345",0
;	output R16:R17 = 0x3039
.include "m2560def.inc"

.def n_MSB = R16
.def n_LSB = R17
.def i = R18
.def c = R19
.def zero = R20
.def ten = R21


; code/program memory, constants, starts from 0x0000
               .cseg                       
string:        .db "12345",0


main:
    ldi ZH, high(string << 1)   ; initialize Z point to string's address
    ldi ZL, low(string << 1)
    clr R16                     ; initialize registers for getting result
    clr R17
    rcall atoi
end:
    rjmp end


atoi:
    ; Prologue
    push YL
    push YH
	push ZL
	push ZH
    push i
    push c
    push zero
    push ten
	push r1
	push r0
    in YL, SPL
    in YH, SPH
    sbiw Y, 0
    out SPH, YH
    out SPL, YL
    ; Function body
loop:
    ldi zero, 0     ; initialize some constant value
    ldi ten, 10
    lpm c, Z+       ; retrive char in string to c
    cpi c, '0'
    brlo return     ; if char is less than '0'
    cpi c, '9'+1          
    brsh return     ; if char is greater than '9'
    subi c, '0'     ; c = c - '0'
    mul n_MSB, ten  ; n = n * 10
	cp r1, zero		
	brne return		; r1 != 0 --> n_MSB * 10 overflow --> n > 65536
    mov n_MSB, r0
    mul n_LSB, ten
    mov n_LSB, r0
    add n_MSB, r1
    add n_LSB, c	; n = n + c
    adc n_MSB, zero
    rjmp loop
return:
    ; Epilogue
    adiw Y, 0
    out SPH, YH
    out SPL, YL
	pop r0
	pop r1
    pop ten
    pop zero
    pop c
    pop i
	pop ZH
	pop ZL
    pop YH
    pop YL
    ret

