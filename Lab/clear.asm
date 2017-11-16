.INCLUDE "m2560def.inc"

.MACRO CLEAR
LDI ZH, HIGH(@0)
LDI ZL, LOW(@0)

LDI YH, HIGH(@1)
LDI YL, LOW(@1)

SER R16
LOOP:
ST Z+, R16
CP ZH, YH
BRNE LOOP
CP ZL, YL
BRNE LOOP
ST Z, R16
.ENDMACRO

CLEAR 0X0200, 0X0204
END: RJMP END

PD0 - INT0

.ORG
INT0addr:    RJMP SOFT_INIT


MAIN:
    ... ENABLE INTO...
    LDI TEMP, 0B0000_0001
    OUT DDRD, TEMP
    OUT PORTD, TEMP