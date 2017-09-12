; Author: Jack (z5129432)
; Date: 12/09/2017
; Version: 1
; Hardware diagram:                  
;   R3(PL4)    1        2       3       A
;   R2(PL5)    4        5       6       B
;   R1(PL6)    7        8       9       C
;   R0(PL7)    *        0       #       D
;           C0(PL3) C1(PL2) C2(PL1) C3(PL0)
;


.include "m2560def.inc"

.def config=R16
.def key=R17
.def row=
.def a=R18
.def b=R19
.def c=R20


rjmp main
; functions defination


delay:
    ; generate a short delay
    push config
    ldi config, 0xFF
    delay_loop:
        dec config
        cpi config, 0x00
        brne delay_loop
    pop config
    ret


key_scan:
    ; output key and row in following format
    ;
    ; key:                                                    invalid
    ; 0000 1000 --> 0000 0100 --> 0000 0010 --> 0000 0001 --> 0000 0000  
    ;
    ; row:                                                    invalid
    ; 1000 0000 --> 0100 0000 --> 0010 0000 --> 0001 0000 --> 0000 1000 
    push config
    ; column loop initialization
    scan_loop:
        ldi key, 0b0000_1000
        col_scan:
            ; Config = not Key = key - 0b1111_1111:                   invalid                           
            ; 1111 0111 --> 0111 1011 --> 0011 1101 --> 0001 1110 --> 0000 1111    
            mov config, key
            subi config, 0b1111_1111
            out PORTL, config
            rcall delay
                ldi row, 0b1000_0000
                row_scan:
                    in config, PINL
                    and config, row    ; mask other bits
                    cpi config, 0      ; zero mean having button pressed
                    breq scan_end
                    ; loop control
                    lsr row
                    cpi row, 0b0000_1000
                    brne row_scan
            ; column loop control
            lsr key
            cpi key, 0b0000_0000
            brne col_scan
        rjmp scan_loop
    scan_end:
        pop config
        ret


convert:
    ; convert key and row into ASCII value, store it in key
    ;   R3(PL4)    1        2       3       A
    ;   R2(PL5)    4        5       6       B
    ;   R1(PL6)    7        8       9       C
    ;   R0(PL7)    *        0       #       D
    ;           C0(PL3) C1(PL2) C2(PL1) C3(PL0)
    ;
    ; key mapping
    ; R0  R1  R2  R3  C0  C1  C2  C3
    ; 0b0001_0001  -->  1
    ; 0b0001_0010  -->  2
    ; 0b0001_0100  -->  3
    ; 0b0001_1000  -->  A 
    ;
    ; 0b0010_0001  -->  4 
    ; 0b0010_0010  -->  5 
    ; 0b0010_0100  -->  6 
    ; 0b0010_1000  -->  B
    ;
    ; 0b0100_0001  -->  7   
    ; 0b0100_0010  -->  8 
    ; 0b0100_0100  -->  9 
    ; 0b0100_1000  -->  C
    ;
    ; 0b1000_0001  -->  *
    ; 0b1000_0001  -->  0 
    ; 0b1000_0010  -->  # 
    ; 0b1000_0100  -->  D 
    ; 
    add key, row
    cpi key, 0b0001_0001
    breq key_number
    cpi key, 0b0001_0010
    breq key_number
    cpi key, 0b0001_0100
    breq key_number
    cpi key, 0b0001_1000
    breq key_letter

    cpi key, 0b0010_0001
    breq key_number
    cpi key, 0b0010_0010
    breq key_number
    cpi key, 0b0010_0100
    breq key_number
    cpi key, 0b0010_1000
    breq key_letter

    cpi key, 0b0100_0001
    breq key_number
    cpi key, 0b0100_0010
    breq key_number
    cpi key, 0b0100_0100
    breq key_number
    cpi key, 0b0100_1000
    breq key_letter

    cpi key, 0b1000_0001
    breq key_star
    cpi key, 0b1000_0001
    breq key_number
    cpi key, 0b1000_0010
    breq key_hash
    cpi key, 0b1000_0100
    breq key_letter

    key_number:
        ldi row, '0'
        add key, row
        rjmp convert_end
    key_letter:
        ldi row, 'A'
        add key, row
        rjmp convert_end
    key_hash:
        ldi key, '#'
        rjmp convert_end
    key_star:
        ldi key, '*'
        rjmp convert_end
    convert_end:
        ret


main:
    ;  Configue：
    ;  PortL         7   6   5   4   3   2   1   0
    ;  key           R0  R1  R2  R3  C0  C1  C2  C3
    ;  Mode   (input)0   0   0   0   1   1   1   1(output)
    ldi config, 0b00001111
    out DDRL, config
    rcall key_scan
    rcall convert


end:
    rjmp end

