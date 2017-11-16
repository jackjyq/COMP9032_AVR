.INCLUDE "m2560def.inc"

.DSEG
BIG:      .BYTE 20
LITTLE:   .BYTE 20

.CSEG
        RJMP    MAIN
A:      .DW     0X0323, 0XF0, 0X05, 0X7F, 0X8D, 0X03, 0XF0, 0X05, 0X7F, 0X8D

ENDIAN:
; PROLOGUE
PUSH    XH
PUSH    XL
PUSH    YH
PUSH    YL
PUSH    ZH
PUSH    ZL
PUSH    R16
PUSH    R17

IN      YH,     SPH
IN      YL,     SPL
SBIW    Y,      12
OUT     SPH,    YH
OUT     SPL,    YL

STD     Y+1,    R16
STD     Y+2,    R17
STD     Y+3,    R18
STD     Y+4,    R19
STD     Y+5,    R20
STD     Y+6,    R21

; FUNCTION BODY
LDD     XH,     Y+1
LDD     XL,     Y+2
LDD     ZH,     Y+5
LDD     ZL,     Y+6

LDI     R16,    10 - 1  ; LOOP TEN TIMES
LOOP_BIG:
LPM     R17, Z+ 
ST      X+, R17
DEC     R16
CPI     R16,    0
BRNE    LOOP_BIG

LDD     XH,     Y+3
LDD     XL,     Y+4
LDI     R16,    10 - 1  ; LOOP TEN TIMES
LOOP_LITTLE:
LPM     R17, Z+     ; R16 IS ORIGIN VALUE
ST      -X, R17
DEC     R16
CPI     R16,    0
BRNE    LOOP_LITTLE

; EPILUGUE
ADIW    Y,  12
OUT     SPH,        YH
OUT     SPL,        YL
POP     R17
POP     R16
POP     ZL
POP     ZH
POP     YL
POP     YH
POP     XL
POP     XH
RET

MAIN:
LDI     R16, HIGH(BIG)
LDI     R17, LOW(BIG)
LDI     R18, HIGH(LITTLE)
LDI     R19, LOW(LITTLE)
LDI		R22,	0
LDI		R23,	10
ADD		R19,	R23
ADC		R18,	R22
LDI     R20, HIGH(A << 1)
LDI     R21, LOW(A << 1)
RCALL   ENDIAN

END:    RJMP    END