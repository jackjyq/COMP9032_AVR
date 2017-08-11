.include "m2560def.inc"
.def a = r17
.def i = r18
.def n = r19
.def anH = r21
.def anL = r20
.def sumH = r16
.def sumL = r15

ldi i, 0
mov anL, a
ldi anH, 0
ldi n, 4

loop:
cp n, i
breq end
mul anL, a
mov r5, r0
mul anL, a
add r5, r1
mov r4, r0
movw r21:r20, r5:r4

add sumL, r4
adc sumH, r5
inc i
rjmp loop

end:
rjmp end
