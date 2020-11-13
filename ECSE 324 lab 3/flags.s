.equ PIXEL_BUFF, 0xC8000000
.equ CHAR_BUFF, 0xC9000000 
.equ PS2_DATA, 0xFF200100
.global _start
//Linpei Duan, 260835863
_start:
        bl      input_loop
end:
        b       end

@ TODO: copy VGA driver here.
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
@ TODO: copy PS/2 driver here.
read_PS2_data_ASM:
	PUSH {R1-LR}
	LDR R3, =PS2_DATA
	LDR R3, [R3]
	ASR R4, R3, #15
	AND R4, R4, #0x1
	CMP R4, #1
	BNE INVALID
	STRB R3,[R0]
	MOV R0, #1
	B read_END
INVALID:
	MOV R0,#0
	B read_END
read_END:
	POP {R1-LR}
	BX LR
@ TODO: adapt this function to draw a real-life flag of your choice.
draw_real_life_flag:
		//flag of Vietnam
		PUSH {R4, LR}
		SUB SP, SP, #8
		LDR R3, .flags_L77
		STR R3, [SP]
		MOV R0, #0
		MOV R1, #0
		MOV R2, #320
		MOV R3, #240
		BL draw_rectangle
		MOV R0, #160
		MOV R1, #120
		MOV R2, #50
		LDR R4, .flags_L77+4
		MOV R3, R4
		BL draw_star
		ADD SP, SP, #8
		POP {R4,PC}
.flags_L77:
        .word   45248
		.word   452000
@ TODO: adapt this function to draw an imaginary flag of your choice.
draw_imaginary_flag:
		//flag of Angelina's Kingdom
        PUSH {R4,LR}
		SUB SP,SP,#16
		LDR R3, .flags_L88
		STR R3, [SP]
		MOV R0, #0
		MOV R1, #0
		MOV R2, #160
		MOV R3, #120
		BL draw_rectangle
		LDR R3, .flags_L88+4
		STR R3, [SP]
		MOV R0, #160
		MOV R1, #0
		MOV R2, #160
		MOV R3, #120
		BL draw_rectangle
		LDR R3, .flags_L88+8
		STR R3, [SP]
		MOV R0, #0
		MOV R1, #120
		MOV R2, #160
		MOV R3, #120
		BL draw_rectangle
		LDR R3, .flags_L88+12
		STR R3, [SP]
		MOV R0, #160
		MOV R1, #120
		MOV R2, #160
		MOV R3, #120
		BL draw_rectangle
		MOV R0, #160
		MOV R1, #120
		MOV R2, #50
		LDR R4, .flags_L88+16
		MOV R3, R4
		BL draw_star
		ADD SP, SP, #16
		POP {R4,PC}
.flags_L88:
		.word 	400000
		.word   452000
		.word   500000
		.word   3000
		.word   65535
draw_texan_flag:
        push    {r4, lr}
        sub     sp, sp, #8
        ldr     r3, .flags_L32
        str     r3, [sp]
        mov     r3, #240
        mov     r2, #106
        mov     r1, #0
        mov     r0, r1
        bl      draw_rectangle
        ldr     r4, .flags_L32+4
        mov     r3, r4
        mov     r2, #43
        mov     r1, #120
        mov     r0, #53
        bl      draw_star
        str     r4, [sp]
        mov     r3, #120
        mov     r2, #214
        mov     r1, #0
        mov     r0, #106
        bl      draw_rectangle
        ldr     r3, .flags_L32+8
        str     r3, [sp]
        mov     r3, #120
        mov     r2, #214
        mov     r1, r3
        mov     r0, #106
        bl      draw_rectangle
        add     sp, sp, #8
        pop     {r4, pc}
.flags_L32:
        .word   2911
        .word   65535
        .word   45248

draw_rectangle:
        push    {r4, r5, r6, r7, r8, r9, r10, lr}
        ldr     r7, [sp, #32]
        add     r9, r1, r3
        cmp     r1, r9
        popge   {r4, r5, r6, r7, r8, r9, r10, pc}
        mov     r8, r0
        mov     r5, r1
        add     r6, r0, r2
        b       .flags_L2
.flags_L5:
        add     r5, r5, #1
        cmp     r5, r9
        popeq   {r4, r5, r6, r7, r8, r9, r10, pc}
.flags_L2:
        cmp     r8, r6
        movlt   r4, r8
        bge     .flags_L5
.flags_L4:
        mov     r2, r7
        mov     r1, r5
        mov     r0, r4
        bl      VGA_draw_point_ASM
        add     r4, r4, #1
        cmp     r4, r6
        bne     .flags_L4
        b       .flags_L5
should_fill_star_pixel:
        push    {r4, r5, r6, lr}
        lsl     lr, r2, #1
        cmp     r2, r0
        blt     .flags_L17
        add     r3, r2, r2, lsl #3
        add     r3, r2, r3, lsl #1
        lsl     r3, r3, #2
        ldr     ip, .flags_L19
        smull   r4, r5, r3, ip
        asr     r3, r3, #31
        rsb     r3, r3, r5, asr #5
        cmp     r1, r3
        blt     .flags_L18
        rsb     ip, r2, r2, lsl #5
        lsl     ip, ip, #2
        ldr     r4, .flags_L19
        smull   r5, r6, ip, r4
        asr     ip, ip, #31
        rsb     ip, ip, r6, asr #5
        cmp     r1, ip
        bge     .flags_L14
        sub     r2, r1, r3
        add     r2, r2, r2, lsl #2
        add     r2, r2, r2, lsl #2
        rsb     r2, r2, r2, lsl #3
        ldr     r3, .flags_L19+4
        smull   ip, r1, r3, r2
        asr     r3, r2, #31
        rsb     r3, r3, r1, asr #5
        cmp     r3, r0
        movge   r0, #0
        movlt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L17:
        sub     r0, lr, r0
        bl      should_fill_star_pixel
        pop     {r4, r5, r6, pc}
.flags_L18:
        add     r1, r1, r1, lsl #2
        add     r1, r1, r1, lsl #2
        ldr     r3, .flags_L19+8
        smull   ip, lr, r1, r3
        asr     r1, r1, #31
        sub     r1, r1, lr, asr #5
        add     r2, r1, r2
        cmp     r2, r0
        movge   r0, #0
        movlt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L14:
        add     ip, r1, r1, lsl #2
        add     ip, ip, ip, lsl #2
        ldr     r4, .flags_L19+8
        smull   r5, r6, ip, r4
        asr     ip, ip, #31
        sub     ip, ip, r6, asr #5
        add     r2, ip, r2
        cmp     r2, r0
        bge     .flags_L15
        sub     r0, lr, r0
        sub     r3, r1, r3
        add     r3, r3, r3, lsl #2
        add     r3, r3, r3, lsl #2
        rsb     r3, r3, r3, lsl #3
        ldr     r2, .flags_L19+4
        smull   r1, ip, r3, r2
        asr     r3, r3, #31
        rsb     r3, r3, ip, asr #5
        cmp     r0, r3
        movle   r0, #0
        movgt   r0, #1
        pop     {r4, r5, r6, pc}
.flags_L15:
        mov     r0, #0
        pop     {r4, r5, r6, pc}
.flags_L19:
        .word   1374389535
        .word   954437177
        .word   1808407283
draw_star:
        push    {r4, r5, r6, r7, r8, r9, r10, fp, lr}
        sub     sp, sp, #12
        lsl     r7, r2, #1
        cmp     r7, #0
        ble     .flags_L21
        str     r3, [sp, #4]
        mov     r6, r2
        sub     r8, r1, r2
        sub     fp, r7, r2
        add     fp, fp, r1
        sub     r10, r2, r1
        sub     r9, r0, r2
        b       .flags_L23
.flags_L29:
        ldr     r2, [sp, #4]
        mov     r1, r8
        add     r0, r9, r4
        bl      VGA_draw_point_ASM
.flags_L24:
        add     r4, r4, #1
        cmp     r4, r7
        beq     .flags_L28
.flags_L25:
        mov     r2, r6
        mov     r1, r5
        mov     r0, r4
        bl      should_fill_star_pixel
        cmp     r0, #0
        beq     .flags_L24
        b       .flags_L29
.flags_L28:
        add     r8, r8, #1
        cmp     r8, fp
        beq     .flags_L21
.flags_L23:
        add     r5, r10, r8
        mov     r4, #0
        b       .flags_L25
.flags_L21:
        add     sp, sp, #12
        pop     {r4, r5, r6, r7, r8, r9, r10, fp, pc}
input_loop:
        push    {r4, r5, r6, r7, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      draw_texan_flag
        mov     r6, #0
        mov     r4, r6
        mov     r5, r6
        ldr     r7, .flags_L52
        b       .flags_L39
.flags_L46:
        bl      draw_real_life_flag
.flags_L39:
        strb    r5, [sp, #7]
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .flags_L39
        cmp     r6, #0
        movne   r6, r5
        bne     .flags_L39
        ldrb    r3, [sp, #7]    @ zero_extendqisi2
        cmp     r3, #240
        moveq   r6, #1
        beq     .flags_L39
        cmp     r3, #28
        subeq   r4, r4, #1
        beq     .flags_L44
        cmp     r3, #35
        addeq   r4, r4, #1
.flags_L44:
        cmp     r4, #0
        blt     .flags_L45
        smull   r2, r3, r7, r4
        sub     r3, r3, r4, asr #31
        add     r3, r3, r3, lsl #1
        sub     r4, r4, r3
        bl      VGA_clear_pixelbuff_ASM
        cmp     r4, #1
        beq     .flags_L46
        cmp     r4, #2
        beq     .flags_L47
        cmp     r4, #0
        bne     .flags_L39
        bl      draw_texan_flag
        b       .flags_L39
.flags_L45:
        bl      VGA_clear_pixelbuff_ASM
.flags_L47:
        bl      draw_imaginary_flag
        mov     r4, #2
        b       .flags_L39
.flags_L52:
        .word   1431655766
