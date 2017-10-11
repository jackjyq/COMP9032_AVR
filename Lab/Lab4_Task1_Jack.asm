; AUTHOR: Jack Jiang
; DATE: 23/09/2017
; VERSION: 1
; DESCRIPTION:
;   Write an assembly program that displays characters inputted from the keypad on the LCD.
;   When the first line is full, the display goes to the next line.
;   When the two lines are all full, the display is cleared and ready to display a new set of characters.


            .INCLUDE    "m2560def.inc"


;   Register defination:
            .DEF        ARG1=R16
            .DEF        ARG2=R17
            .DEF        ARG3=R18
            .DEF        ARG4=R19
            .DEF        RETURN1=R20
            .DEF        RETURN2=R21
		    .DEF        GLOBAL1=R22
            .DEF        GLOBAL2=R23
            .DEF        TEMP1=R24
            .DEF        TEMP2=R25


;   LCD instruction defination:
            .EQU        LCD_CLR=0b00000001
            .EQU        LCD_RTN=0b00000010
            .EQU        LCD_ETR=0b00000100
            .EQU        LCD_ETR_S=0             ; S=1: shift, S=0: don't shift
            .EQU        LCD_ETR_ID=1            ; ID=1: increments, ID=0 decrements
            .EQU        LCD_DSP=0b00001000
            .EQU        LCD_DSP_B=0             ; B=1: blink on, B=0: blink off
            .EQU        LCD_DSP_C=1             ; C=1: display cursor, C=0: not display cursor
            .EQU        LCD_DSP_D=2             ; D=1: display on, D=0: display off
            .EQU        LCD_SFT=0b00010000
            .EQU        LCD_SFT_RL=2            ; RL=0: left, RL=1: right
            .EQU        LCD_SFT_SC=3            ; SC=0: cursor, SC=1: entire display
            .EQU        LCD_FUN=0b00100000
            .EQU        LCD_FUN_F=2             ; F=1: 5*10 dots, F=0: 5*7 dots
            .EQU        LCD_FUN_N=3             ; N=0: 1 line display, N=1: 2 lines display
            .EQU        LCD_FUN_DL=4            ; DL=1: 8 bit mode, DL=0: 4 bit mode
            .EQU        LCD_CG= 0b01000000
            .EQU        LCD_DD= 0b10000000


            RJMP        RESET
            .CSEG                              ; code/program memory, constants, starts from 0x0000
;====================================  Convert Dictionary ===================================

; Used for function KEYPAD_CONVERT
KEYPAD_CONVERT_KEY:
            .db 0xEE, 0xDE, 0xBE, 0x7E
            .db 0xED, 0xDD, 0xBD, 0x7D
            .db 0xEB, 0xDB, 0xBB, 0x7B
            .db 0xE7, 0xD7, 0xB7, 0x77


;   convert to LCD characters
KEYPAD_CONVERT_VALUE:
            .db 0x31, 0x32, 0x33, 0x41
            .db 0x34, 0x35, 0x36, 0x42
            .db 0x37, 0x38, 0x39, 0x43
            .db 0x2A, 0x30, 0x23, 0x44

;===================================== Delay Function =========================================

.MACRO      TEST_DELAY
; using LED to test Delay
TEST_DELAY_LOOP:
            LDI         TEMP1,      0xFF
            OUT         PORTC,      TEMP1
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            RCALL       DELAY
            LDI         TEMP1,      0x00
            OUT         PORTC,      TEMP1
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            RCALL       DELAY
            RJMP        TEST_DELAY_LOOP
.ENDMACRO


DELAY:
; This function is use to generate a delay:
;           ARG2:ARG1 * 0.1 ms
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
            PUSH        TEMP2
            LDI         TEMP1,      1
            LDI         TEMP2,      0
            ADD         ARG1,       TEMP1       ; to make sure delay is ARG2:ARG1 * 0.1 ms
            ADC         ARG2,       TEMP2       ; but not (ARG2:ARG1-1) * 0.1 ms
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
            POP         TEMP2
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET

;=================================== LCD driver ========================================

.MACRO      TEST_LCD_DRIVER
            CLR         TEMP1
TEST_LCD_DRIVER_LINE1:
            LDI         ARG1,       0b01001100  ; display letter L
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       LOW(3000)   ; delay
            LDI         ARG2,       HIGH(3000)
            RCALL       DELAY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      16          ; if i != 16:
            BRNE        TEST_LCD_DRIVER_LINE1   ;   TEST_LCD_DRIVER_LINE1
            LDI         ARG1,       0b11000000  ; else: change to the second line
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            CLR         TEMP1
TEST_LCD_DRIVER_LINE2:
            LDI         ARG1,       0b01000011  ; display letter C
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       LOW(3000)   ; delay
            LDI         ARG2,       HIGH(3000)
            RCALL       DELAY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      16          ; if i != 16:
            BRNE        TEST_LCD_DRIVER_LINE2   ;   TEST_LCD_DRIVER_LINE2
            LDI         ARG1,       LCD_CLR     ; else: clear screen
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
.ENDMACRO


.MACRO      INIT_LCD_IO
;   LCD(2*16 charactor) Initialization:
;   PF 0~7  --  Data 0~7
;   PA4     --  BE
;   PA5     --  RW      --  0:WRITE 1:READ
;   PA6     --  E       --  ENABLE READ/WRITE
;   PA7     --  RS      --  0:INSTRUCTION/BUSY
;                           1:DATA
            LDI         TEMP1,      0b11111111
            OUT         DDRF,       TEMP1           ; PF7~PF0: output
            IN          TEMP1,      DDRA
            ORI         TEMP1,      0b11110000
            OUT         DDRA,       TEMP1           ; PA7~PA4: output
.ENDMACRO


LCD_WRITE_INS:
;   this function can write ARG1 as an instruction to LCD
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write         <--(using this)
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


LCD_WRITE_DATA:
;   this function can write ARG1 as data to LCD
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write
;   0       1       Busy flag
;   1       0       DR write        <--(using this)
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


LCD_CHECK_BUSY:
;   this function return and only retrun when BUSY is reset
;   LCD can in any mode before calling this funtion
;   however, when it returns, LCD will be set to DATA WRITE mode
;   LCD Registers:
;   RS      RW      MODE
;   0       0       IR write
;   0       1       Busy flag       <-- (when checking)
;   1       0       DR write        <-- (when ending)
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


LCD_SOFT_INIT:
; LCD software initialization
; S=1: shift
; S=0: don't shift          <--
; ID=1: increments          <--
; ID=0: decrements
; B=1: blink on
; B=0: blink off            <--
; C=1: display cursor       <--
; C=0: not display cursor
; D=1: display on           <--
; D=0: display off
; RL=0: left
; RL=1: right
; SC=0: cursor
; SC=1: entire display
; F=1: 5*10 dots
; F=0: 5*7 dots             <--
; N=0: 1 line display
; N=1: 2 lines display      <--
; DL=1: 8 bit mode          <--
; DL=0: 4 bit mode
; prologue
            PUSH        ARG1
            PUSH        ARG2
            PUSH        TEMP1
            PUSH        TEMP2
; function body
            LDI         ARG1,       LOW(150)
            LDI         ARG2,       HIGH(150)
            RCALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            RCALL       LCD_WRITE_INS
            LDI         ARG1,       LOW(41)
            LDI         ARG2,       HIGH(41)
            RCALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            RCALL       LCD_WRITE_INS
            LDI         ARG1,       LOW(1)
            LDI         ARG2,       HIGH(1)
            RCALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL) |(1<<LCD_FUN_N)    ; 8 bit mode & 2 lines display
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_DSP                                      ; trun off display
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_CLR
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_ETR | (1<<LCD_ETR_ID)                    ; increasement mode
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_DSP | (1<<LCD_DSP_D)  | (1<<LCD_DSP_C)   ; trun on display & cursor
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
; epilogue
            POP         TEMP2
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET

;===================================== Keypad Driver ==========================================

.MACRO      TEST_KEYPAD_CONVERT
            LDI         ARG1,       0x7D
            RCALL       KEYPAD_CONVERT
.ENDMACRO


.MACRO      TEST_KEYPAD_SCAN
; using LED to test KEYPAD_SCAN
TEST_KEYPAD_SCAN_LOOP:
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            OUT         PORTC,     RETURN1
            RJMP        TEST_KEYPAD_SCAN_LOOP
.ENDMACRO


.MACRO      TEST_KEYPAD_WITH_CONVERT
; using LED to test CONVERT_TO_HEX_LOOP
TEST_KEYPAD_WITH_CONVERT_LOOP:
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            RCALL       KEYPAD_CONVERT
            OUT         PORTC,     RETURN1
            RJMP        TEST_KEYPAD_WITH_CONVERT_LOOP
.ENDMACRO


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


KEYPAD_SCAN:
;   scan keypad, return when released:
;   Keypad:
;         C0       C1      C2      C3
;   R0    1        2       3       A
;   R1    4        5       6       B
;   R2    7        8       9       C
;   R3   *(E)      0      #(F)     D
;   RETURN1 format:
;   C3 C2 C1 C0 R3 R2 R1 R0
;	Actived button are represented by 0, other bits are 1, for example:
;	if button 8 (C1,R2) are pushed, then RETURN1 will be: 11011011
            PUSH        TEMP1
            PUSH        TEMP2
KEYPAD_SCAN_PRESS:
            LDI         RETURN1,    0b11110111
            ; Column mask(RETURN1):
            ; 1111 0111 --> 0111 1011 --> 0011 1101 --> 0001 1110  --> 0000 1111 (invalid)
KEYPAD_SCAN_LOOP:
            CPI         RETURN1,    0b00001111          ; if mask is invalid:
            BREQ        KEYPAD_SCAN_PRESS               ;   goto KEYPAD_SCAN_PRESS
            STS         PORTL,      RETURN1             ; else: write column
            LDI         TEMP1,      0xFF                ; {
KEYPAD_SCAN_DELAY:                                      ; delay
            DEC         TEMP1                           ;
            BRNE        KEYPAD_SCAN_DELAY               ; }
            LDS         TEMP2,    PINL                  ; read row
            ANDI        TEMP2,    0b11110000            ;   mask low 4 bits
            CPI         TEMP2,    0b11110000            ; if having key pressed:
            BRNE        KEYPAD_SCAN_END                 ;   goto KEYPAD_SCAN_RELEASE
            LSR         RETURN1                         ; else: right shift mask
            RJMP        KEYPAD_SCAN_LOOP                ;   goto KEYPAD_SCAN_LOOP
KEYPAD_SCAN_END:
            ANDI        RETURN1,    0b00001111          ; mask high 4 bits
            ANDI        TEMP2,      0b11110000          ; mask high 4 bits
            ADD         RETURN1,    TEMP2
            POP         TEMP2
            POP         TEMP1
            RET


KEYPAD_CHECK_RELEASE:
; Only return when no key is pressed
            PUSH        TEMP1
            PUSH        TEMP2
            PUSH        RETURN1
KEYPAD_CHECK_RELEASE_LOOP:
            LDI         RETURN1,    0b11110111
            ; Column mask(RETURN1):
            ; 1111 0111 --> 0111 1011 --> 0011 1101 --> 0001 1110  --> 0000 1111 (invalid)
KEYPAD_CHECK_RELEASE_COL:
            CPI         RETURN1,    0b00001111          ; if mask is invalid:
            BREQ        KEYPAD_CHECK_RELEASE_END        ;   goto KEYPAD_CHECK_RELEASE_END
            STS         PORTL,      RETURN1             ; else: write column
            LDI         TEMP1,      0xFF                ; {
KEYPAD_CHECK_RELEASE_DELAY:                             ; delay
            DEC         TEMP1                           ;
            BRNE        KEYPAD_CHECK_RELEASE_DELAY      ; }
KEYPAD_CHECK_RELEASE_ROW:
            LDS         TEMP2,    PINL                  ; read row
            ANDI        TEMP2,    0b11110000            ;   mask low 4 bits
            CPI         TEMP2,    0b11110000            ; if having key pressed:
            BRNE        KEYPAD_CHECK_RELEASE_LOOP       ;   goto KEYPAD_CHECK_RELEASE_LOOP
            LSR         RETURN1                         ; else: right shift mask
            RJMP        KEYPAD_CHECK_RELEASE_COL        ;   goto KEYPAD_CHECK_RELEASE_COL
KEYPAD_CHECK_RELEASE_END:
            POP         RETURN1
            POP         TEMP2
            POP         TEMP1
            RET


KEYPAD_CONVERT:
; Convert keypad ARG1 to target format RETURN1
            PUSH        ARG1
            PUSH        TEMP1
            PUSH        TEMP2
; Funciton body
            LDI         ZH,            HIGH(KEYPAD_CONVERT_KEY << 1)
            LDI         ZL,            LOW(KEYPAD_CONVERT_KEY << 1)
            LDI         TEMP1,         0x00                 ; TEMP2:TEPM1 is Index of dictionary
            LDI         TEMP2,         0x00
KEYPAD_CONVERT_SEARCH_KEY:
            LPM         RETURN1,       Z+
            CP          RETURN1,       ARG1                  ; if KEY != ARG1:
            BREQ        KEYPAD_CONVERT_LOAD_VALUE           ;   go to KEYPAD_CONVERT_LOAD_VALUE
            ADIW        TEMP2:TEMP1,   1                 ; else: Index += 2
            RJMP        KEYPAD_CONVERT_SEARCH_KEY           ;   go to KEYPAD_CONVERT_SEARCH_KEY
KEYPAD_CONVERT_LOAD_VALUE:
            LDI         ZH,             HIGH(KEYPAD_CONVERT_VALUE << 1)
            LDI         ZL,             LOW(KEYPAD_CONVERT_VALUE << 1)
            ADD         ZL,             TEMP1                   ; Z = Z + Index
            ADC         ZH,             TEMP2
            LPM         RETURN1,        Z
; Function end
            POP         TEMP2
            POP         TEMP1
            POP         ARG1
            RET

;============================== End of Function and Macros ================================
			RJMP		END


RESET:
            INIT_LCD_IO
            INIT_KEYPAD_IO
            RCALL       LCD_SOFT_INIT


MAIN:
            CLR         TEMP1                  ; TEMP1 is the counter of displayed characters
DISPLAY_LINE_1:
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            RCALL       KEYPAD_CONVERT
            MOV         ARG1,       RETURN1
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      16          ; if i != 16:
            BRNE        DISPLAY_LINE_1          ;   go to DISPLAY_LINE_1
            LDI         ARG1,       0b11000000  ; else: change to the second line
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY

            CLR         TEMP1
DISPLAY_LINE_2:                   
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            RCALL       KEYPAD_CONVERT
            MOV         ARG1,       RETURN1
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      17          ; if i != 17:
            BRNE        DISPLAY_LINE_2          ;   go to DISPLAY_LINE_2
            LDI         ARG1,       0b11000000  ; else: change to the second line    
            LDI         ARG1,       LCD_CLR     ; else: clear screen
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            RJMP        MAIN


END:
            RJMP        END
