; AUTHOR: Jack Jiang
; DATE: 23/09/2017
; VERSION: 1
; DESCRIPTION:
;   Write an assembly program that displays characters inputted from the keypad on the LCD.
;   When the first line is full, the display goes to the next line.
;   When the two lines are all full, the display is cleared and ready to display a new set of characters.

            .INCLUDE    "m2560def.inc"

            .DEF        ARG1=R16
            .DEF        ARG2=R17
            .DEF        ARG3=R18
            .DEF        ARG4=R19
            .DEF        RETURN1=R20
            .DEF        RETURN2=R21
            .DEF        TEMP1=R22
            .DEF        TEMP2=R23
            .DEF        GLOBAL1=R24
            .DEF        GLOBAL2=R25



RESET:
            INIT_LCD_IO
            INIT_KEYPAD_IO


MAIN:




END:
; Function and macro declearation
            RJMP        END

.MACRO      INIT_KEYPAD_IO
;   Keypad Initialization:
;   R3(PL4)    1        2       3       A
;   R2(PL5)    4        5       6       B
;   R1(PL6)    7        8       9       C
;   R0(PL7)    *        0       #       D
;           C0(PL3) C1(PL2) C2(PL1) C3(PL0)
            LDI         TEMP1,      0b00001111
            STS         DDRL,       TEMP1           ; PL7~PL4: inut, PL3~PL0: output
.ENDMACRO

;#################################################################################

.MACRO      INIT_LCD_IO
;   LCD(2*16 charactor) Initialization:
;   PF 0~7  --  Data 0~7
;   PA5     --  RW      --  0:WRITE 1:READ
;   PA6     --  E       --  ENABLE READ/WRITE
;   PA7     --  RS      --  0:INSTRUCTION/BUSY
;                           1:DATA
            LDI         TEMP1,      0b11111111
            OUT         DDRF,       TEMP1           ; PF7~PF0: output
            IN          TEMP1,      DDRA
            ORI         TEMP1,      0b11100000
            OUT         DDRG,       TEMP1           ; PA7~PA5: output
.ENDMACRO

;#################################################################################

.MACRO      INIT_LED_IO
;           LED Initialization:
;           LED0 -- PG0
;           LED1 -- PG1
;           LED2 -- PC0
;           LED3 -- PC1
;           LED4 -- PC2
;           LED5 -- PC3
;           LED6 -- PC4
;           LED7 -- PC5
;           LED8 -- PC6
;           LED9 -- PC7
            LDI         TEMP1,      0b11111111
            OUT         DDRC,       TEMP1           ; PC7~PC0 output
            IN          TEMP1,      DDRG
            ORI         TEMP1,      0b00000011      ; PG1~PG0 output
            OUT         DDRG,       TEMP1
.ENDMACRO

;#################################################################################

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

;#################################################################################

LCD_WRITE_INS:
;   this function can write ARG1 as an instruction to LCD
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write         <--
;   0       1       Busy flag
;   1       0       DR write
;   1       1       DR read
            PUSH        ARG1
            PUSH        TEMP1
            OUT         PORTF,      ARG1
            IN          TEMP1,      PORTA
            ANDI        TEMP1,      0b01011111
            OUT         PORTA,      TEMP1       ; reset RS and RW, IR write mode
            NOP
            SBI         PORTA,      6           ; set ENABLE
            NOP
            NOP
            NOP
            CBI         PORTA,      6           ; reset ENABLE
            NOP
            POP         TEMP1
            POP         ARG1
            RET

;#################################################################################

LCD_WRITE_DATA:
;   this function can write ARG1 as data to LCD
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write
;   0       1       Busy flag
;   1       0       DR write        <--
;   1       1       DR read
            PUSH        ARG1
            PUSH        TEMP1
            OUT         PORTF,      ARG1
            IN          TEMP1,      PORTA
            ORI         TEMP1,      0b10000000  ; set RS
            ANDI        TEMP1,      0b11011111  ; reset RW
            OUT         PORTA,      TEMP1       ; DR write mode
            NOP
            SBI         PORTA,      6           ; set ENABLE
            NOP
            NOP
            NOP
            CBI         PORTA,      6           ; reset ENABLE
            NOP
            POP         TEMP1
            POP         ARG1
            RET


;#################################################################################

LCD_CHECK_BUSY:
;   this function return and only retrun when BUSY is reset
;   LCD can in any mode before calling this funtion
;   however, when it returns, LCD will be set to DATA WRITE mode
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write
;   0       1       Busy flag       <--
;   1       0       DR write
;   1       1       DR read
            PUSH        TEMP1
            LDI         TEMP1,      0b00000000
            OUT         DDRF,       TEMP1       ; set PORT F as input mode
            OUT         PORTF,      TEMP1
            IN          TEMP1,      PORTA
            ANDI        TEMP1,      0b01111111  ; reset RS
            ORI         TEMP1,      0b00100000  ; set RW
            OUT         PORTA,      TEMP1       ; Busy flag read mode
LCD_CHECK_BUSY_LOOP:
            NOP
            SBI         PORTA,      6           ; set ENABLE
            NOP
            NOP
            NOP
            IN          TEMP1,      PINF
            CBI         PORTA,      6           ; reset ENABLE
            SBRC        TEMP1,      7           ; if BUSY:
            RJMP        LCD_CHECK_BUSY_LOOP     ;   repeat reading
            IN          TEMP1,      PORTA       ; else:
            ANDI        TEMP1,      0b01011111
            OUT         PORTA,      TEMP1       ; reset RS and RW, IR write mode
            LDI         TEMP1,      0b11111111
            OUT         DDRF,       TEMP1       ; set PORT F as output mode
            POP         TEMP1
            RET



;#################################################################################

            RJMP        END