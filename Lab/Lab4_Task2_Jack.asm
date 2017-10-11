; AUTHOR: Jack Jiang
; DATE: 23/09/2017
; VERSION: 2
; DESCRIPTION:
;    This program can measure the speed of the motor by counting the number of holes
;    that has been detected using the shaft encoder, and displays the motor speed of on the LCD.
;
; Change Wire Conection:
;                           MOTER MOT -- INPUT POT
;
; Restore Wire Connection:
;                           MOTER MOT -- PE2
;                           INPUT POT -- PK8


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
;========================================  Interupt ===========================================

           .ORG        OVF1addr
           RJMP        TIMER1_INTERUPT

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

;================================== Timer1 Interupt ======================================


.MACRO     INIT_TIME1
; To generate 1s timer 1
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

;=================================== SHAFT driver ========================================

.MACRO      TEST_SHAFT
TEST_SHAFT_LOOP:
            RCALL       READ_SHAFT
            RCALL       TOGGLE_LED
            RJMP        TEST_SHAFT_LOOP
.ENDMACRO


.MACRO      INIT_SHAFT_IO
;           Set PD2 to input mode
;           OPE(+5V) -- Emmitor in Shaft enconder -- active high
;           OPO(PD2) -- LED in Shaft encoder -- active low -- (INPUT MODE)
            IN          TEMP1,      DDRD
            ANDI        TEMP1,      0b11111011      ; set PD2 = 0
            OUT         DDRD,       TEMP1
.ENDMACRO


READ_SHAFT:
;           return when SHAFT change from active to inactive
            PUSH        TEMP1
READ_SHAFT_ACTIVE:
            IN          TEMP1,      PIND
            ANDI        TEMP1,      0b00000100
            CPI         TEMP1,      0               ; if SHAFT inactive:
            BRNE        READ_SHAFT_ACTIVE           ;   read again
READ_SHAFT_INACTIVE:                                ; else: is active
            IN          TEMP1,      PIND
            ANDI        TEMP1,      0b00000100
            CPI         TEMP1,      0               ; if SHAFT active:
            BREQ        READ_SHAFT_INACTIVE         ;   read again
READ_SHAFT_END:                                     ; else: return
            POP         TEMP1
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

;====================================== LED driver ==========================================

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

;================================== Split digits ======================================

.MACRO      TEST_SHOW_NUMBER
            SHOW_SPEED
            LDI         ARG2,       7
            RCALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            RCALL       DELAY
            SHOW_SPEED
            LDI         ARG2,       98
            RCALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            RCALL       DELAY
            SHOW_SPEED
            LDI         ARG2,       100
            RCALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            RCALL       DELAY
            SHOW_SPEED
            LDI         ARG2,       105
            RCALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            RCALL       DELAY
            SHOW_SPEED
            LDI         ARG2,       123
            RCALL       SHOW_NUMBER
            LDI         ARG1,       LOW(20000)
            LDI         ARG2,       HIGH(20000)
            RCALL       DELAY
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
            RJMP        SHOW_NUMBER_1           ;  ARG < 10
; show the first digit
SHOW_NUMBER_3:
            LDI         ARG1,       2           ; highest digit = 2
            LDI         TEMP1,      100
SHOW_NUMBER_3_LOOP:
            MUL         ARG1,      TEMP1
            CP          ARG2,       R0          ; if number >= highest digit * 100:
            BRSH        SHOW_NUMBER_3_END       ;   return highest digit
            DEC         ARG1                   ; else: decrease highest digit by 1
            RJMP        SHOW_NUMBER_3_LOOP      ;   loop
SHOW_NUMBER_3_END:
            LDI         TEMP1,      '0'         ; show the first digit
            ADD         ARG1,      TEMP1
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
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
            RJMP        SHOW_NUMBER_2_LOOP      ;   loop
SHOW_NUMBER_2_END:
            LDI         TEMP1,      '0'         ; show the first digit
            ADD         ARG1,       TEMP1
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            SUB         ARG2,       R0
; show the third digit
SHOW_NUMBER_1:            
            MOV         ARG1,       ARG2
            LDI         TEMP1,      '0'
            ADD         ARG1,       TEMP1
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
; function end
            POP         R0
            POP         TEMP1
            POP         ARG2
            POP         ARG1
            RET


.MACRO      SHOW_SPEED
            LDI         ARG1,       LCD_CLR     ; else: clear screen
            RCALL       LCD_WRITE_INS
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       'S'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       'p'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       'e'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       'e'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       'd'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       ':'
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
            LDI         ARG1,       ' '
            RCALL       LCD_WRITE_DATA
            RCALL       LCD_CHECK_BUSY
.ENDMACRO

;============================== End of Functions and Macros ==================================

RESET:
            INIT_LCD_IO
            INIT_SHAFT_IO
			INIT_LED_IO
            INIT_TIME1
            RCALL       LCD_SOFT_INIT
            SEI
            CLR         GLOBAL1

MAIN:
;   Calculate speed in GLOBAL1
            CLR         TEMP1
COUNT_HOLE:
            RCALL       READ_SHAFT				; if shaft active:
            INC         TEMP1                   ;       Count hole ++
            CPI         TEMP1,          4       ; if Count hole != 4:
            BRNE        COUNT_HOLE              ;        loop read shaft status
            INC         GLOBAL1                 ; else:  Speed ++
            RJMP        MAIN                    ;        loop main function


TIMER1_INTERUPT:
            SHOW_SPEED
			; OUT			PORTC,			GLOBAL1
            MOV         ARG2,           GLOBAL1
            RCALL       SHOW_NUMBER
            CLR         GLOBAL1
            RETI


END:
            RJMP        END