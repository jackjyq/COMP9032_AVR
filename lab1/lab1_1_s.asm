;Author:Jack(z5129432)
;Last Modification:1/08/2017
;Version:V0.1.0
;Description:calculating the greatest common divisor of two numbers
;for minimum code size
;16 byte, 10 clock time
;while(a!=b)
;{
;	if(a>b)
;		a = a - b;
;	else
;		b = b - a;
;}
;reture 0;

.include "m2560def.inc"
.def a = r16
.def b = r17

begin:
cp a, b		;compare a and b
breq end	;if a = b, then end the program
brlt altb	;if a < b, jump to a_less

blta:		;if a > b, then a = a - b
	sub a, b
	rjmp	begin

altb:		;if a < b, then b = b - a
	sub b, a
	rjmp	begin

end:			;end of the program
	rjmp end	

