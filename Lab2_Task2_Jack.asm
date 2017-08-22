;Author: Jack (z5129432)
;Date: 22/08/2017
;Version: 1
;Description: String to integer convertor
;
;
;Test Sample:


.include "m2560def.inc"

.def integerMSB = R16
.def integerLSB = R17

.equ asciiZero = 48

; code/program memory, constants, starts from 0x0000
               .cseg                       
string:        .dw 0x ; 

