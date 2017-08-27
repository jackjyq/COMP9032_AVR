;Author: Jack (z5129432)
;Date: 27/08/2017
;Version: 1
;Description: String to integer convertor
;
;
;Test Sample:


.include "m2560def.inc"

.def integerMSB = R16
.def integerLSB = R17
.def char0 = R18
.def char1 = R19
.def char2 = R20
.def char3 = R21
.def char4 = R22
.equ asciiZero = 0x30

; code/program memory, constants, starts from 0x0000
               .cseg                       
string:        .dw 0x3132333435 ; '0' is 0x30, this string is '12345' 

; main
ldi ZH, high(string << 1)
ldi ZL, low(string <<1)

lpm char0, Z+
lpm char1, Z+
lpm char2, Z+
lpm char3, Z+
lpm char4, Z
rcall atoi

end: rjmp end

; atoi
atoi:   ret

