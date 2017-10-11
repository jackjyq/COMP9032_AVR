; AUTHOR: Jack Jiang
; DATE: 3/10/2017
; VERSION: 1
; DESCRIPTION:
;   The accident location can be set after the simulation starts.
;   The search can be interrupted by the user if the mission needs to be aborted early.
;

;======================================  Configuartion =========================================

            .EQU        DRONE_SPEED =  2000    ;   ms
            .EQU        DRONE_HEIGHT = 10      ;   m
            .EQU        MAP_SIZE = 64

;======================================  Defination =========================================

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

		    .DEF        ACCIDENT_X=R2
            .DEF        ACCIDENT_Y=R3


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



;====================================  Interupt vector ======================================
            
            .CSEG
            .ORG         0x0000
            JMP        RESET


            .ORG          INT0addr
            ; Button RIGHT -- PD0 --- INT0
            JMP          RIGHT_INT


            .ORG          INT1addr
            ; Button LEFT -- PD1 --- INT1
            JMP          LEFT_INT

;=========================================  Data ============================================

            .ORG         0x0072


; Mountain map data
             .INCLUDE    "mountain_map.inc"
            ;  .INCLUDE    "mountain_debug.inc"


; Keypad Convert Dictionary
KEYPAD_CONVERT_KEY:
            .db 0xEE, 0xDE, 0xBE, 0x7E
            .db 0xED, 0xDD, 0xBD, 0x7D
            .db 0xEB, 0xDB, 0xBB, 0x7B
            .db 0xE7, 0xD7, 0xB7, 0x77
; KEYPAD_CONVERT_VALUE:
;             .db 0x31, 0x32, 0x33, 0x41
;             .db 0x34, 0x35, 0x36, 0x42
;             .db 0x37, 0x38, 0x39, 0x43
;             .db 0x2A, 0x30, 0x23, 0x44
KEYPAD_CONVERT_VALUE:
            .db 0x01, 0x02, 0x03, 0x0A
            .db 0x04, 0x05, 0x06, 0x0B
            .db 0x07, 0x08, 0x09, 0x0C
            .db 0x0E, 0x00, 0x0F, 0x0D


;   Some strings for display
STRING_INPUT_X:
            .db "INPUT X: ",0
STRING_INPUT_Y:
            .db "INPUT Y: ",0
STRING_INPUT_OV:
            .db "INPUT OV ",0
STRING_TRY_AGAIN:
            .db "TRY AGAIN",0
STRING_STATUS_G:
            .db "STATUS: GROUND",0,0
STRING_STATUS_S:
            .db "STATUS: SEARCH",0,0
STRING_STATUS_R:
            .db "STATUS: RETURN",0,0
STRING_STATUS_I:
            .db "STATUS: INSPECT",0
STRING_STATUS_T:
            .db "STATUS: TAKEOFF",0
STRING_STATUS_L:
            .db "STATUS: LANDING",0
STRING_ACCIDENT:
            .db "ACCIDENT: ",0,0
STRING_NOT_FOUND:
            .db "NOT FOUND",0
STRING_X:
            .db "X:",0,0
STRING_Y:
            .db "Y:",0,0
STRING_Z:
            .db "Z:",0,0
STRING_COMMA:
            .db ",",0

;================================ Interupt initialization ==================================

.MACRO     INIT_BUTTON_RIGHT
; initialize interupt of right button
            IN          TEMP1,      DDRD
            ANDI        TEMP1,      0b11111110
            OUT         DDRD,       TEMP1                    ; set PD0 input mode
            IN          TEMP1,      PORTD
            ORI         TEMP1,      0b00000001
            OUT         PORTD,      TEMP1                    ; active pull-up resister of PD0 and PD1
            LDI         TEMP1,      (2<<ISC00)               ; set INT0 as falling edge triggered interupt
            STS         EICRA,      TEMP1
            ; IN          TEMP1,      EIMSK                    ; enalbe INT0
            ; ORI         TEMP1,      (1<<INT0)
            ; OUT         EIMSK,      TEMP1
.ENDMACRO


.MACRO     INIT_BUTTON_LEFT
; initialize interupt of left button
            IN          TEMP1,      DDRD
            ANDI        TEMP1,      0b11111101
            OUT         DDRD,       TEMP1                    ; set PD1 input mode
            IN          TEMP1,      PORTD
            ORI         TEMP1,      0b00000010
            OUT         PORTD,      TEMP1                    ; active pull-up resister of PD1
            LDI         TEMP1,      (2<<ISC10)               ; set INT1 as falling edge triggered interupt
            STS         EICRA,      TEMP1
            ; IN          TEMP1,      EIMSK                    ; enalbe INT1
            ; ORI         TEMP1,      (1<<INT1)
            ; OUT         EIMSK,      TEMP1
.ENDMACRO


.MACRO     INIT_TIME1
; To generate 1 second by using timer 1
; Timer1 is 16 bits timer, 2^16 = 65536
; 65536 * 1/16M s * Clock_Selection = 1s
; Clock_Selection = 256
; Therefore: TCCR1B = 0b00000100
            LDI         TEMP1,        0b00000000
            STS         TCCR1A,       TEMP1         ; Normal mode
            LDI         TEMP1,        0b00000100
            STS         TCCR1B,       TEMP1         ; Clock selection = 256
            LDI         TEMP1,        (1<<TOIE1)
            STS         TIMSK1,       TEMP1         ; Overflow enabled
.ENDMACRO

;========================================== Delay =============================================

.MACRO      TEST_DELAY
; using LED to test Delay
TEST_DELAY_LOOP:
            LDI         TEMP1,      0xFF
            OUT         PORTC,      TEMP1
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            CALL        DELAY
            LDI         TEMP1,      0x00
            OUT         PORTC,      TEMP1
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            CALL        DELAY
            JMP         TEST_DELAY_LOOP
.ENDMACRO


DELAY:
; This function is use to generate a delay:
;           ARG2:ARG1 * 0.1 ms
; The longest delay it can generate is 6.5 s
;
; For example, if you want to generate 1 s delay, you should:
;           LDI         ARG1,       LOW(10000)
;           LDI         ARG2,       HIGH(10000)
;           CALL       DELAY
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
            JMP        DELAY_OUT               ; 2 clock cycles
DELAY_END:
            POP         TEMP2
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET

;==================================== LED driver =========================================

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


TOGGLE_LED:
            PUSH        TEMP1
            PUSH        TEMP2
            IN          TEMP1,      PORTC
            LDI         TEMP2,      0xFF
            SUB         TEMP2,      TEMP1
            OUT         PORTC,      TEMP2
            POP         TEMP2
            POP         TEMP1
            RET


CLR_LED:
            PUSH        TEMP1
            LDI         TEMP1,      0b00000000
            OUT         PORTC,      TEMP1
            IN          TEMP1,      PORTG
            ANDI        TEMP1,      0b11111100
            OUT         PORTG,      TEMP1
            POP         TEMP1
            RET


FUL_LED:
            PUSH        TEMP1
            LDI         TEMP1,      0b11111111
            OUT         PORTC,      TEMP1
            IN          TEMP1,      PORTG
            ORI         TEMP1,      0b00000011
            OUT         PORTG,      TEMP1
            POP         TEMP1
            RET


INC_LED:
            PUSH        ARG1
            PUSH        ARG2
            PUSH        TEMP1
            PUSH        TEMP2
            CALL        CLR_LED
            LDI         ARG1,        LOW(3000)
            LDI         ARG2,        HIGH(3000)
            CALL        DELAY
            LDI         TEMP1,       0b00000001
INC_LED_LOOP:
            OUT         PORTC,      TEMP1
            CPI         TEMP1,      0xFF
            BREQ        INC_LED_END
            LSL         TEMP1
            INC         TEMP1
            CALL       DELAY
            JMP        INC_LED_LOOP
INC_LED_END:
            POP         TEMP2
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET


DEC_LED:
            PUSH        ARG1
            PUSH        ARG2
            PUSH        TEMP1
            PUSH        TEMP2
            CALL       CLR_LED
            LDI         ARG1,        LOW(3000)
            LDI         ARG2,        HIGH(3000)
            LDI         TEMP1,       0xFF
DEC_LED_LOOP:
            OUT         PORTC,      TEMP1
            CPI         TEMP1,      0
            BREQ        DEC_LED_END
            LSR         TEMP1
            CALL       DELAY
            JMP        DEC_LED_LOOP
DEC_LED_END:
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
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,       LOW(3000)   ; delay
            LDI         ARG2,       HIGH(3000)
            CALL       DELAY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      16          ; if i != 16:
            BRNE        TEST_LCD_DRIVER_LINE1   ;   TEST_LCD_DRIVER_LINE1
            LDI         ARG1,       0b11000000  ; else: change to the second line
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            CLR         TEMP1
TEST_LCD_DRIVER_LINE2:
            LDI         ARG1,       0b01000011  ; display letter C
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,       LOW(3000)   ; delay
            LDI         ARG2,       HIGH(3000)
            CALL       DELAY
            INC         TEMP1                   ; i ++
            CPI         TEMP1,      16          ; if i != 16:
            BRNE        TEST_LCD_DRIVER_LINE2   ;   TEST_LCD_DRIVER_LINE2
            LDI         ARG1,       LCD_CLR     ; else: clear screen
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
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
            JMP        LCD_CHECK_BUSY_LOOP     ;   repeat reading
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
            CALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            CALL       LCD_WRITE_INS
            LDI         ARG1,       LOW(41)
            LDI         ARG2,       HIGH(41)
            CALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            CALL       LCD_WRITE_INS
            LDI         ARG1,       LOW(1)
            LDI         ARG2,       HIGH(1)
            CALL       DELAY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL)
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_FUN | (1<<LCD_FUN_DL) |(1<<LCD_FUN_N)    ; 8 bit mode & 2 lines display
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_DSP                                      ; trun off display
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_CLR
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_ETR | (1<<LCD_ETR_ID)                    ; increasement mode
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            LDI         ARG1,      LCD_DSP | (1<<LCD_DSP_D)  | (1<<LCD_DSP_C)   ; trun on display & cursor
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
; epilogue
            POP         TEMP2
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET


.MACRO      DISPLAY_STRING
            LDI         ZH,         HIGH(@0 << 1)
            LDI         ZL,         LOW(@0 << 1)
DISPLAY_STRING_LOOP:
            LPM         ARG1,       Z+
            CPI         ARG1,        0
            BREQ        DISPLAY_STRING_END
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
            JMP        DISPLAY_STRING_LOOP
DISPLAY_STRING_END:
.ENDMACRO


DISPLAY_CLR:
; clear screen
            PUSH       ARG1
            LDI        ARG1,       LCD_CLR
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            POP        ARG1
            RET


DISPLAY_NEWLINE:
; change to a new line
            PUSH        ARG1
            LDI        ARG1,       0b11000000
            CALL       LCD_WRITE_INS
            CALL       LCD_CHECK_BUSY
            POP        ARG1
            RET

;===================================== Keypad Driver ==========================================

.MACRO      TEST_KEYPAD_CONVERT
            LDI         ARG1,       0x7D
            CALL       KEYPAD_CONVERT
.ENDMACRO


.MACRO      TEST_KEYPAD_SCAN
; using LED to test KEYPAD_SCAN
TEST_KEYPAD_SCAN_LOOP:
            CALL       KEYPAD_SCAN
            CALL       KEYPAD_CHECK_RELEASE
            OUT         PORTC,     RETURN1
            JMP        TEST_KEYPAD_SCAN_LOOP
.ENDMACRO


.MACRO      TEST_KEYPAD_WITH_CONVERT
; using LED to test CONVERT_TO_HEX_LOOP
TEST_KEYPAD_WITH_CONVERT_LOOP:
            CALL       KEYPAD_SCAN
            CALL       KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            CALL       KEYPAD_CONVERT
            OUT         PORTC,     RETURN1
            JMP        TEST_KEYPAD_WITH_CONVERT_LOOP
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
            JMP        KEYPAD_SCAN_LOOP                ;   goto KEYPAD_SCAN_LOOP
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
            JMP        KEYPAD_CHECK_RELEASE_COL        ;   goto KEYPAD_CHECK_RELEASE_COL
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
            LDI         TEMP1,         0x00                  ; TEMP2:TEPM1 is Index of dictionary
            LDI         TEMP2,         0x00
KEYPAD_CONVERT_SEARCH_KEY:
            LPM         RETURN1,       Z+
            CP          RETURN1,       ARG1                  ; if KEY != ARG1:
            BREQ        KEYPAD_CONVERT_LOAD_VALUE            ;   go to KEYPAD_CONVERT_LOAD_VALUE
            ADIW        TEMP2:TEMP1,   1                     ; else: Index += 2
            JMP        KEYPAD_CONVERT_SEARCH_KEY            ;   go to KEYPAD_CONVERT_SEARCH_KEY
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

;===================================== Motor Driver =========================================

.MACRO      INIT_MOT_IO
;   PE3(Timer3) --> Mot(output)
            IN          TEMP1,      DDRE
            ORI         TEMP1,      0b00010000
            OUT         DDRE,       TEMP1           ; PE3: output
.ENDMACRO


.MACRO      TEST_MOTOR
TEST_MOTOR_LOOP:
            SET_MOTOR_SPEED         0x00
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            CALL       DELAY
            SET_MOTOR_SPEED         0x80
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            CALL       DELAY
            SET_MOTOR_SPEED         0xFF
            LDI         ARG1,       LOW(10000)
            LDI         ARG2,       HIGH(10000)
            CALL       DELAY
            JMP        TEST_MOTOR_LOOP
.ENDMACRO


.MACRO      SET_MOTOR_SPEED
;  TCCR3A:
;       COM3A1=1 --> Compare Output Mode for Channel A
;       WGM30=1 --> PWM, Phase Correct, 8-bit Mode
;  TCCR3B:
;       CS32=0, CS31=0, CS30=1 --> clk/1 Mode
            CLR         TEMP1
            STS         OCR3BH,     TEMP1
            LDI         TEMP1,      @0
            STS         OCR3BL,     TEMP1
            LDI         TEMP1,      (1 << CS30)
            STS         TCCR3B,     TEMP1
            LDI         TEMP1,      (1 << WGM30) | (1 << COM3B1)
            STS         TCCR3A,     TEMP1
.ENDMACRO

;=============================== User interaction ===================================

.MACRO      TEST_SHOW_NUMBER
            LDI         ARG2,       7
            CALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            CALL       DELAY
            LDI         ARG2,       98
            CALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            CALL       DELAY
            LDI         ARG2,       100
            CALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            CALL       DELAY
            LDI         ARG2,       105
            CALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            CALL       DELAY
            LDI         ARG2,       123
            CALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            CALL       DELAY
.ENDMACRO


.MACRO      TEST_SHOW_LOCATION
;   for example:
;   TEST_SHOW_LOCATION   x,  y,  DRONE_HEIGHT
            CALL        DISPLAY_CLR
            LDI         ARG1,           0
            LDI         ARG2,           0
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            CALL        DISPLAY_CLR
            LDI         ARG1,           1
            LDI         ARG2,           2
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            CALL        DISPLAY_CLR
            LDI         ARG1,           2
            LDI         ARG2,           1
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            CALL        DISPLAY_CLR
            LDI         ARG1,           63
            LDI         ARG2,           0
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            CALL        DISPLAY_CLR
            LDI         ARG1,           64
            LDI         ARG2,           0
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
            CALL        DISPLAY_CLR
            LDI         ARG1,           63
            LDI         ARG2,           63
            LDI         ARG3,           0
            RCALL       SHOW_LOCATION_X
            RCALL       SHOW_LOCATION_Y
            RCALL       SHOW_LOCATION_Z
            RCALL       KEYPAD_SCAN
            RCALL       KEYPAD_CHECK_RELEASE
.ENDMACRO


SHOW_NUMBER:
; givin a number in ARG2 (ARG1 will be used to call LCD_WRITE_DATA)
; show this number in LCD
            PUSH        ARG1
            PUSH        ARG2
            PUSH        TEMP1
            PUSH        R0
; function body
            CPI         ARG2,       100
            BRSH        SHOW_NUMBER_3           ;  ARG >=100
            CPI         ARG2,       10
            BRSH        SHOW_NUMBER_2           ;  100 > ARG >= 10
            JMP        SHOW_NUMBER_1           ;  ARG < 10
; show the first digit
SHOW_NUMBER_3:
            LDI         ARG1,       2           ; highest digit = 2
            LDI         TEMP1,      100
SHOW_NUMBER_3_LOOP:
            MUL         ARG1,      TEMP1
            CP          ARG2,       R0          ; if number >= highest digit * 100:
            BRSH        SHOW_NUMBER_3_END       ;   return highest digit
            DEC         ARG1                   ; else: decrease highest digit by 1
            JMP        SHOW_NUMBER_3_LOOP      ;   loop
SHOW_NUMBER_3_END:
            LDI         TEMP1,      '0'         ; show the first digit
            ADD         ARG1,      TEMP1
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
            SUB         ARG2,       R0
; show the second digit
SHOW_NUMBER_2:
            LDI         ARG1,       9           ; highest digit = 2
            LDI         TEMP1,      10
SHOW_NUMBER_2_LOOP:
            MUL         ARG1,       TEMP1
            CP          ARG2,       R0          ; if number >= highest digit * 10:
            BRSH        SHOW_NUMBER_2_END       ;   return highest digit
            DEC         ARG1                    ; else: decrease highest digit by 1
            JMP        SHOW_NUMBER_2_LOOP      ;   loop
SHOW_NUMBER_2_END:
            LDI         TEMP1,      '0'         ; show the first digit
            ADD         ARG1,       TEMP1
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
            SUB         ARG2,       R0
; show the third digit
SHOW_NUMBER_1:
            MOV         ARG1,       ARG2
            LDI         TEMP1,      '0'
            ADD         ARG1,       TEMP1
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
; function end
            POP         R0
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET


.MACRO      INPUT_NUMBER
; used in USER_INPUT, don't use in other place
; input a number, which will be stored into RETURN2
; show this number in LCD Interactively
; press # to confirm
; guarantee input will be in range[0, 255]
            CLR         RETURN2
; input the first digits
INPUT_NUMBER_1:
            CALL        KEYPAD_SCAN
            CALL        KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            CALL        KEYPAD_CONVERT
            CPI         RETURN1,    10          ; if input != digit:
            BRSH        INPUT_NUMBER_1          ;   input agint
            ADD         RETURN2,    RETURN1     ; else: Calculate RETURN2 = RETURN1
            MOV         ARG1,       RETURN1     ;       display digit
            LDI         TEMP1,      '0'
            ADD         ARG1,       TEMP1
            CALL        LCD_WRITE_DATA
            CALL        LCD_CHECK_BUSY
; input the first digits or #
INPUT_NUMBER_2:
            CALL        KEYPAD_SCAN
            CALL        KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            CALL        KEYPAD_CONVERT
            CPI         RETURN1,    0x0F        ; if input == #:
            BREQ        INPUT_NUMBER_END        ;   END
            CPI         RETURN1,    10          ; elif input != digit:
            BRSH        INPUT_NUMBER_2          ;   input agint
            LDI         TEMP1,      10          ; R0 = RETURN2 * 10
            MUL         RETURN2,    TEMP1
            ADD         R0,         RETURN1     ; R0 = RETURN2 * 10 + RETURN1
            MOV         RETURN2,    R0          ; RETURN2 = R0
            MOV         ARG1,       RETURN1     ; display digit
            LDI         TEMP1,      '0'
            ADD         ARG1,       TEMP1
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
INPUT_NUMBER_3:
            CALL       KEYPAD_SCAN
            CALL       KEYPAD_CHECK_RELEASE
            MOV         ARG1,       RETURN1
            CALL       KEYPAD_CONVERT
            CPI         RETURN1,    0x0F        ; if input == #:
            BREQ        INPUT_NUMBER_END        ;   END
            CPI         RETURN1,    10          ; elif input != digit:
            BRSH        INPUT_NUMBER_3          ;   input again
            LDI         TEMP1,      10          ; R0 = RETURN2 * 10
            MUL         RETURN2,    TEMP1       ; if R0 > 255:
            LDI         TEMP1,      1           ;   input again
            CP          R1,         TEMP1
            BRSH        INPUT_NUMBER_3
            ADD         R0,         RETURN1     ; R0 = RETURN2 * 10 + RETURN1
            LDI         TEMP1,      0
            ADC         TEMP1,      TEMP1
            CPI         TEMP1,      1
            BRSH        INPUT_NUMBER_3
            MOV         RETURN2,    R0          ;       RETURN2 = R0
            MOV         ARG1,       RETURN1     ;       display digit
            LDI         TEMP1,      '0'
            ADD         ARG1,       TEMP1
            CALL       LCD_WRITE_DATA
            CALL       LCD_CHECK_BUSY
INPUT_NUMBER_END:
.ENDMACRO


SHOW_LOCATION_X:
;   current location is stored in ARG1 ARG2
            PUSH        ARG1
            PUSH        ARG2
            PUSH        RETURN1
            PUSH        TEMP1
;   start function
            MOV         ARG2,       ARG1        ; preserve ARG1
            DISPLAY_STRING          STRING_X    ; ARG1  will be lost
            CALL                    SHOW_NUMBER
;   end of function
            POP         TEMP1
            POP         RETURN1
            POP         ARG2
            POP         ARG1
            RET


SHOW_LOCATION_Y:
;   current location is stored in ARG1 ARG2
            PUSH        ARG1
            PUSH        ARG2
            PUSH        RETURN1
            PUSH        TEMP1
;   start function
            DISPLAY_STRING          STRING_COMMA
            DISPLAY_STRING          STRING_Y    ; ARG1  will be lost
            CALL                    SHOW_NUMBER
;   end of function
            POP         TEMP1
            POP         RETURN1
            POP         ARG2
            POP         ARG1
            RET


SHOW_LOCATION_Z:
;   INPUT：
;    ARG1, ARG2 for x, y
;    ARG3 is the height of the drone
;
;   show the height of the mountain + ARG3
            PUSH        ARG1
            PUSH        ARG2
            PUSH        ARG3
            PUSH        TEMP1
            PUSH        R0
            PUSH        R1
            PUSH        ZH
            PUSH        ZL
;   start function
            MOV         TEMP1,          ARG1                   ; preserv ARG1
            DISPLAY_STRING              STRING_COMMA           ; ARG1  will be lost
            DISPLAY_STRING              STRING_Z               ; ARG1  will be lost
            MOV         ARG1,           TEMP1                  ; restore ARG1
            LDI         ZH,            HIGH(MOUNTAIN_MAP << 1)
            LDI         ZL,            LOW(MOUNTAIN_MAP << 1)
            LDI         TEMP1,         MAP_SIZE              ; R1:R0 = MAP_SIZE * y
            MUL         ARG2,          TEMP1                 ; {}
            LDI         TEMP1,         0                     ; R1:R0 = MAP_SIZE * y + x
            ADD         R0,            ARG1                  ; {
            ADC         R1,            TEMP1                 ; }
            ADD         ZL,            R0                    ; ZL += R0
            ADC         ZH,            R1                    ; ZH += R1
            LPM         ARG2,          Z                     ; show HEIGHT + ARG3
            ADD         ARG2,          ARG3                  ; {
            CALL        SHOW_NUMBER                          ; }
;   end of function
            POP         ZL
            POP         ZH
            POP         R1
            POP         R0
            POP         TEMP1
            POP         ARG3
            POP         ARG2
            POP         ARG1
            RET

;================================= Module ==========================================

.MACRO      TEST_USER_INPUT
            CLR         ACCIDENT_X
            CLR         ACCIDENT_Y
            USER_INPUT
            CALL        DISPLAY_CLR
            MOV         ARG2,       ACCIDENT_X
            CALL       SHOW_NUMBER
            CALL        DISPLAY_NEWLINE
            MOV         ARG2,       ACCIDENT_Y
            CALL       SHOW_NUMBER
.ENDMACRO


.MACRO      USER_INPUT
; input accident and store into ACCIDENT_X and ACCIDENT_Y
USER_INPUT_X:
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_INPUT_X
            INPUT_NUMBER
            CPI         RETURN2,    64            ; if input out of range:
            BRSH        USER_INPUT_X_OV           ;     USER_INPUT_X_OV
            MOV         ACCIDENT_X,    RETURN2
            JMP         USER_INPUT_Y
USER_INPUT_X_OV:
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_INPUT_OV
            CALL        DISPLAY_NEWLINE
            DISPLAY_STRING          STRING_TRY_AGAIN
            LDI         ARG1,       LOW(30000)
            LDI         ARG2,       HIGH(30000)
            CALL       DELAY
            JMP        USER_INPUT_X
USER_INPUT_Y:
            CALL        DISPLAY_NEWLINE
            DISPLAY_STRING          STRING_INPUT_Y
            INPUT_NUMBER
            CPI         RETURN2,    64            ; if input out of range:
            BRSH        USER_INPUT_Y_OV             ;     USER_INPUT_OV
            MOV         ACCIDENT_Y,    RETURN2
            JMP        USER_INPUT_END            ; else: end
USER_INPUT_Y_OV:
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_INPUT_OV
            CALL        DISPLAY_NEWLINE
            DISPLAY_STRING          STRING_TRY_AGAIN
            LDI         ARG1,       LOW(30000)
            LDI         ARG2,       HIGH(30000)
            CALL       DELAY
            JMP        USER_INPUT_X
USER_INPUT_END:
.ENDMACRO



SHOW_SEARCH_STATUS:
            PUSH        ARG1
            PUSH        ARG2
            PUSH        ARG3
            PUSH        TEMP1
            PUSH        GLOBAL1
            PUSH        GLOBAL2
;   function start
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_STATUS_S
            CALL        DISPLAY_NEWLINE
            MOV         ARG1,       GLOBAL1
            MOV         ARG2,       GLOBAL2
            LDI         ARG3,       DRONE_HEIGHT
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z
            LDI         ARG1,       LOW(DRONE_SPEED)
            LDI         ARG2,       HIGH(DRONE_SPEED)
            CALL        DELAY
;   funciton end
            POP         GLOBAL2
            POP         GLOBAL1
            POP         TEMP1
            POP         ARG3
            POP         ARG2
            POP         ARG1
            RET


SHOW_RETURN_STATUS:
            PUSH        ARG1
            PUSH        ARG2
            PUSH        ARG3
            PUSH        TEMP1
            PUSH        GLOBAL1
            PUSH        GLOBAL2
;   function start
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_STATUS_R
            CALL        DISPLAY_NEWLINE
            MOV         ARG1,       GLOBAL1
            MOV         ARG2,       GLOBAL2
            LDI         ARG3,       DRONE_HEIGHT
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z
            LDI         ARG1,       LOW(DRONE_SPEED)
            LDI         ARG2,       HIGH(DRONE_SPEED)
            CALL        DELAY
;   funciton end
            POP         GLOBAL2
            POP         GLOBAL1
            POP         TEMP1
            POP         ARG3
            POP         ARG2
            POP         ARG1
            RET


DRONE_INSPECT:
;   use ARG1 and ARG2 as current location
            PUSH        ARG1
            PUSH        ARG2
            PUSH        ARG3
            PUSH        TEMP1
;   function start
            LDI         ARG3,       DRONE_HEIGHT
            CALL        DISPLAY_CLR
            MOV         TEMP1,      ARG1
            DISPLAY_STRING          STRING_STATUS_I
            MOV         ARG1,       TEMP1
            CALL        DISPLAY_NEWLINE
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
            CALL        TOGGLE_LED
            LDI         ARG1,       LOW(5000)
            LDI         ARG2,       HIGH(5000)
            CALL        DELAY
;   funciton end
            POP         TEMP1
            POP         ARG3
            POP         ARG2
            POP         ARG1
            RET


;====================================================================================
			JMP		END


RESET:
;   initialise emulation system
            INIT_LCD_IO
            INIT_LED_IO
            INIT_KEYPAD_IO
            INIT_MOT_IO
            INIT_BUTTON_RIGHT
            INIT_BUTTON_LEFT
            CALL       LCD_SOFT_INIT
            CLR         ACCIDENT_X                  ; accident location
            CLR         ACCIDENT_Y
            CLR         GLOBAL1                     ; current location
            CLR         GLOBAL2

MAIN:
;   GROUNDED MODE
            USER_INPUT                              ; get accident point and store it into ACCIDENT_X ACCIDENT_Y
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_STATUS_G
            CALL        DISPLAY_NEWLINE
            CLR         ARG1                        ; X, Y = (0, 0)
            CLR         ARG2
            CLR         ARG3                        ; height = 0, means drone is on the ground
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z
;   Configue interupted
            IN          TEMP1,      EIMSK          ; enalbe INT1(left button)
            ORI         TEMP1,      (1<<INT1)
            OUT         EIMSK,      TEMP1
            IN          TEMP1,      EIMSK          ; disalbe INT0(right button)
            ORI         TEMP1,      (0<<INT0)
            OUT         EIMSK,      TEMP1
            SEI                                    ; enable global interupt
STAND_BY:
            RJMP        STAND_BY



LEFT_INT:
;   SEARCH MODE
;   Configue interupted            
            IN          TEMP1,      EIMSK           ; disalbe INT1(left button)
            ANDI        TEMP1,      (0<<INT1)
            OUT         EIMSK,      TEMP1
            IN          TEMP1,      EIMSK           ; enalbe INT0(right button)
            ORI         TEMP1,      (1<<INT0)
            OUT         EIMSK,      TEMP1
            CLI                                     ; disable global interupt   
;   TAKE OFF
            CALL        INC_LED
            SET_MOTOR_SPEED         0xFF
            LDI         ARG3,       0               ; drone start from the ground
DRONE_TAKE_OFF:
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_STATUS_T
            CALL        DISPLAY_NEWLINE
            CLR         ARG1                        ; take off on X, Y = (0, 0)
            CLR         ARG2
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z             ; show z = z(0, 0) + ARG3
            INC         ARG3
            CPI         ARG3,       DRONE_HEIGHT
            BRSH        DRONE_SEARCH
            LDI         ARG1,       LOW(3000)
            LDI         ARG2,       HIGH(3000)
            CALL        DELAY
            RJMP        DRONE_TAKE_OFF

DRONE_SEARCH:            
            SEI                                     ; enable global interupt
;   use ARG1 and ARG2 as current location
SEARCH_INC:
;   x will increase by 1 after each loop
            CP          GLOBAL1,       ACCIDENT_X     ; if x != ACCIDENT_X:
            BRNE        SEARCH_INC_NEXT         ;   SEARCH_INC_NEXT
            CP          GLOBAL2,       ACCIDENT_Y     ; elif y == ACCIDENT_Y:
            BREQ        SEARCH_END              ;   SEARCH_END
SEARCH_INC_NEXT:
            CPI         GLOBAL1,       MAP_SIZE-1  ; if x == MAP_SIZE-1:
            BRSH        SEARCH_INC_END          ;   SEARCH_INC_END
            CALL        SHOW_SEARCH_STATUS
            INC         GLOBAL1                    ; else: x++
            JMP         SEARCH_INC              ;   SEARCH_INC
SEARCH_INC_END:
            CALL        SHOW_SEARCH_STATUS
            INC         GLOBAL2                    ; y++
            CALL        SHOW_SEARCH_STATUS
SEARCH_DEC:
;   x will decrease by 1 after each loop
            CP          GLOBAL1,       ACCIDENT_X     ; if x != ACCIDENT_X:
            BRNE        SEARCH_DEC_NEXT         ;   SEARCH_DEC_NEXT
            CP          GLOBAL2,       ACCIDENT_Y     ; elif y == ACCIDENT_Y:
            BREQ        SEARCH_END              ;   SEARCH_END
SEARCH_DEC_NEXT:
            CPI         GLOBAL1,       1           ; if x == 0:
            BRLO        SEARCH_DEC_END          ;   SEARCH_DEC_END
            CALL        SHOW_SEARCH_STATUS
            DEC         GLOBAL1                    ; else: x--
            JMP         SEARCH_DEC              ;   SEARCH_DEC
SEARCH_DEC_END:
            CALL        SHOW_SEARCH_STATUS
            INC         GLOBAL2                    ; y++
            CALL        SHOW_SEARCH_STATUS
            JMP         SEARCH_INC
SEARCH_END:
            CALL        SHOW_SEARCH_STATUS
            CLI                                   ; disable global interupt        

;   INSPECT
            SET_MOTOR_SPEED         0x40
            MOV        ARG1,        GLOBAL1
            MOV        ARG2,        GLOBAL2
            CALL       DRONE_INSPECT
            RJMP       END_SIMULATION



RIGHT_INT:
;   MARK ABORTED
			LDI			TEMP1,		0xFF
            MOV         ACCIDENT_X, TEMP1
            RJMP        END_SIMULATION



END_SIMULATION:
;   Configue interupted    
            IN          TEMP1,      EIMSK          ; disalbe INT1(left button)
            ANDI        TEMP1,      (0<<INT1)
            OUT         EIMSK,      TEMP1
            IN          TEMP1,      EIMSK           ; disalbe INT0(right button)
            ANDI        TEMP1,      (0<<INT0)
            OUT         EIMSK,      TEMP1
            CLI                                     ; disable global interupt

DRONE_RETURN:
            SET_MOTOR_SPEED         0xFF
RETURN_Y:
;   y will decrease by 1 after each loop
            CALL        SHOW_RETURN_STATUS
            CPI         GLOBAL2,       1           ; if y == 0:
            BRLO        RETURN_X                   ;   RETURN_X
            DEC         GLOBAL2                    ; else: y--
            JMP         RETURN_Y                   ;   RETURN_Y
RETURN_X:
;   x will decrease by 1 after each loop
            CALL        SHOW_RETURN_STATUS
            CPI         GLOBAL1,       1           ; if x == 0:
            BRLO        RETURN_END                 ;   RETURN_END
            DEC         GLOBAL1                    ; else: x--
            JMP         RETURN_X                   ;   RETURN_X
RETURN_END:
            CALL        SHOW_RETURN_STATUS

;   landing
            LDI         ARG3,       DRONE_HEIGHT        ; initialize the height of drone
DRONE_LANDING:
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_STATUS_L
            CALL        DISPLAY_NEWLINE
            CLR         ARG1                    ; show X, Y = (0, 0)
            CLR         ARG2
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            CALL        SHOW_LOCATION_Z         ; show z = z(0, 0) + ARG3
            DEC         ARG3
            CPI         ARG3,       1
            BRLO        DRONE_LANDING_END
            LDI         ARG1,       LOW(3000)
            LDI         ARG2,       HIGH(3000)
            CALL        DELAY
            RJMP         DRONE_LANDING
DRONE_LANDING_END:
            CALL        DEC_LED
            SET_MOTOR_SPEED         0x00

;  SHOW RESULT
            CALL        DISPLAY_CLR
            DISPLAY_STRING          STRING_ACCIDENT
            CALL        DISPLAY_NEWLINE
			LDI			TEMP1,			0xFF
            CP          ACCIDENT_X,   TEMP1
            BREQ        END_SIMULATION_FAIL
END_SIMULATION_SUCCESS:            
            MOV         ARG1,         ACCIDENT_X
            MOV         ARG2,         ACCIDENT_Y
            CALL        SHOW_LOCATION_X
            CALL        SHOW_LOCATION_Y
            JMP         END
END_SIMULATION_FAIL:
            DISPLAY_STRING          STRING_NOT_FOUND



END:
            JMP        END