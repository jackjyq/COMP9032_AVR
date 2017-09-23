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
;   LCD(2*16 charactor)
;   PF 0~7  --  Data 0~7
;   PE5     --  BL
;   PA4     --  BE
;   PA5     --  RW      --  0:WRITE 1:READ
;   PA6     --  E       --  ENABLE READ/WRITE
;   PA7     --  RS      --  0:INSTRUCTION/BUSY
;                           1:DATA
;   LCD register selection:
;   RS      RW      FUNCTION
;   0       0       IR write
;   0       1       Busy flag
;   1       0       DR write
;   1       1       DR read


.INCLUDE "m2560def.inc"

.DEF ARG1=R16
.DEF ARG2=R17
.DEF ARG3=R18
.DEF ARG4=R19
.DEF RETURN1=R20
.DEF RETURN2=R21
.DEF TEMP1=R22
.DEF TEMP2=R23
.DEF GLOBAL1=R24
.DEF GLOBAL2=R25

            RJMP        RESET
; Function and macro declearation

DELAY:
; This function is use to generate a delay:
;           (ARG2:ARG1 - 1) * 0.1 ms
; The longest delay it can generate is 6.5 s
;
; For example, if you want to generate 1 s delay, you should:
;           LDI         ARG1,       LOW(10000)
;           LDI         ARG2,       HIGH(10000)
;           RCALL       DELAY
;
; Calculation:
; Insaid DELAY_IN,  we get:
;          7 clock cycles * 228 = 1596 clock cycles
; Inside DELAY_OUT, we get:
;          (1596 + 5) clock cycles * ARG2:ARG1
; where     1601 clock cycles = 0.1 ms
            PUSH        ARG1
            PUSH        ARG2
            PUSH        TEMP1
DELAY_OUT:
            SUBI        ARG1,       1
            SBCI        ARG2,       0
            BREQ        DELAY_END               ; 1 clock cycle if false
            LDI         TEMP1,      227
DELAY_IN:
            DEC         TEMP1
            NOP
            NOP
            NOP
            NOP
            BRNE        DELAY_IN                ; 2 clock cycles if true
            RJMP        DELAY_OUT               ; 2 clock cycles
DELAY_END:
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET












RESET:


MAIN:


END:
            RJMP        END