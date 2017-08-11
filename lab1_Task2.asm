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
;Test Sample:
;	a = 0x2, n = 0x3, sum = 2 + 4 + 8 = 14 = E
;	

.include "m2560def.inc"

.def a = r16
.def n = r17
.def i = r18	;indacator i in range [1, n]
.def p = r19	;product like a or a * a or a * a * a
.def sumL = r20
.def sumH = r21


;Test code
ldi a, 2
ldi n, 3

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
