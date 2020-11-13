.equ PIXEL_BUFF, 0xC8000000
.equ CHAR_BUFF, 0xC9000000 
.global _start
//Linpei Duan, 260835863
_start:
        bl      draw_test_screen
end:
        b       end

@ TODO: Insert VGA driver functions here.
VGA_draw_point_ASM:
	//R1: y R0: x
	PUSH {R0-R10,LR}
	LDR R3,=PIXEL_BUFF //base
	LSL R5, R1, #10 //y shifts
	LSL R6, R0, #1 //x shifts
	ADD R7, R5, R6 //add up offset
	ADD R3, R3, R7 //add offset to base
	STRH R2, [R3] //color: short=2 bytes=half-word
	POP {R0-R10, LR}
	BX LR
VGA_clear_pixelbuff_ASM:
	//x 0-319 y 0-239 
	PUSH {R0-LR}
	MOV R0, #0 //R0 counts x
	MOV R1, #0 //R1 counts y
	MOV R2, #0 //for clear up
X_P_LOOP:
	CMP R0, #320
	BGE OUT_P_LOOP
	B Y_P_LOOP
increment_x:
	ADD R0,R0,#1
	B X_P_LOOP
Y_P_LOOP:
	CMP R1, #240
	MOVGE R1, #0
	BGE increment_x
	BL VGA_draw_point_ASM 
	ADD R1,R1,#1
	B Y_P_LOOP
OUT_P_LOOP:
	POP {R0-LR}
	BX LR
VGA_write_char_ASM:
	//R0:x 0-79 R1:y 0-59 R2:write to screen
	PUSH {R0-R10, LR}
	//test valid
	CMP R0, #80
	BGE END_WRITE
	CMP R0, #0
	BLT END_WRITE
	CMP R1, #60
	BGE END_WRITE
	CMP R1, #0
	BLT END_WRITE
	
	LDR R5, =CHAR_BUFF
	LSL R6, R1, #7 //shift value
	ADD R7, R6, R0
	ADD R5, R5, R7 //add offset to base
	STRB R2, [R5] //write the value given to base
END_WRITE:
	POP {R0-R10, LR}
	BX LR
VGA_clear_charbuff_ASM:
	//x 0-319 y 0-239 
	PUSH {R0-LR}
	MOV R0, #0 //R0 counts x
	MOV R1, #0 //R1 counts y
	MOV R2, #0
X_CHAR_LOOP:
	CMP R0, #80
	BGE OUT_CHAR_LOOP
	B Y_CHAR_LOOP
increment_x_char:
	ADD R0,R0,#1
	B X_CHAR_LOOP
Y_CHAR_LOOP:
	CMP R1, #60
	MOVGE R1, #0
	BGE increment_x_char
	BL VGA_write_char_ASM 
	ADD R1,R1,#1
	B Y_CHAR_LOOP
OUT_CHAR_LOOP:
	POP {R0-LR}
	BX LR
draw_test_screen:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r6, #0
        ldr     r10, .draw_test_screen_L8
        ldr     r9, .draw_test_screen_L8+4
        ldr     r8, .draw_test_screen_L8+8
        b       .draw_test_screen_L2
.draw_test_screen_L7:
        add     r6, r6, #1
        cmp     r6, #320
        beq     .draw_test_screen_L4
.draw_test_screen_L2:
        smull   r3, r7, r10, r6
        asr     r3, r6, #31
        rsb     r7, r3, r7, asr #2
        lsl     r7, r7, #5
        lsl     r5, r6, #5
        mov     r4, #0
.draw_test_screen_L3:
        smull   r3, r2, r9, r5
        add     r3, r2, r5
        asr     r2, r5, #31
        rsb     r2, r2, r3, asr #9
        orr     r2, r7, r2, lsl #11
        lsl     r3, r4, #5
        smull   r0, r1, r8, r3
        add     r1, r1, r3
        asr     r3, r3, #31
        rsb     r3, r3, r1, asr #7
        orr     r2, r2, r3
        mov     r1, r4
        mov     r0, r6
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        add     r5, r5, #32
        cmp     r4, #240
        bne     .draw_test_screen_L3
        b       .draw_test_screen_L7
.draw_test_screen_L4:
        mov     r2, #72
        mov     r1, #5
        mov     r0, #20
        bl      VGA_write_char_ASM
        mov     r2, #101
        mov     r1, #5
        mov     r0, #21
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #22
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #23
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #24
        bl      VGA_write_char_ASM
        mov     r2, #32
        mov     r1, #5
        mov     r0, #25
        bl      VGA_write_char_ASM
        mov     r2, #87
        mov     r1, #5
        mov     r0, #26
        bl      VGA_write_char_ASM
        mov     r2, #111
        mov     r1, #5
        mov     r0, #27
        bl      VGA_write_char_ASM
        mov     r2, #114
        mov     r1, #5
        mov     r0, #28
        bl      VGA_write_char_ASM
        mov     r2, #108
        mov     r1, #5
        mov     r0, #29
        bl      VGA_write_char_ASM
        mov     r2, #100
        mov     r1, #5
        mov     r0, #30
        bl      VGA_write_char_ASM
        mov     r2, #33
        mov     r1, #5
        mov     r0, #31
        bl      VGA_write_char_ASM
        pop     {r4, r5, r6, r7, r8, r9, r10, pc}
.draw_test_screen_L8:
        .word   1717986919
        .word   -368140053
        .word   -2004318071
