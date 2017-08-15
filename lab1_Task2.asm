;Author: Jack (z5129432)
;Date: 
;Version: 1
;Description: 
;	Calculate sum(a^i) where i in range[1, n]
;	a, n are 8-bit unsigned integer
;	sum is 16 bits unsigned integer
;	minimus the number of register usage
;	for example:
;	sum = a + a * a + (a * a) * a

.include "m2560def.inc"

.def a = r16
.def n = r17
.def p = r19	;product like a or a * a or a * a * a
.def sumL = r20
.def sumH = r21

;Test Sample 1:
;ldi a, 0x2
;ldi n, 0x3
;expected sum = 2 + 4 + 8 = 0xE

;Test Sample 2:
;ldi a, 0xE
;ldi n, 0x3
;expected sum = E + C4 + AB8 = 2954 = 0xB8A

;initialize i = 1, p = 1
ldi p, 1

loop: 	;Calculate sum += p * 1, divided by two steps
mul p, a 	;p *= a
mov p, r0
add sumL, r0 ;sum += p
adc sumH, r1
dec n	; decrease n by 1
brne loop

end:
rjmp end
