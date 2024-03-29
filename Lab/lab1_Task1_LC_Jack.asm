;Author:Jack(z5129432)
;Last Modification:1/08/2017
;Version:V0.1.0
;Description:calculating the greatest common divisor of two numbers
;for minimum code size
;14 byte, 58 clock time for test sample 3
;while(a!=b)
;{
;	if(a>b)
;		a = a - b;
;	else
;		b = b - a;
;}
;reture 0;
;test sample 1: if a = B, b = 7, then the final result is a = b = 1
;test sample 2: if a = 8, b = 4, then the final result is a = b = 4
;test sample 3: if a = 63, b = 9, then the final result is a = b = 9 


.include "m2560def.inc"
.def a = r16
.def b = r17

begin:
cp a, b		;compare a and b
breq begin	;if a = b, then bring the program into a close loop

brlo altb	;if a < b, jump to a_less

blta:		;if a > b, then a = a - b
	sub a, b
	rjmp	begin ;loop

altb:		;if a < b, then b = b - a
	sub b, a
	rjmp	begin ;loop


