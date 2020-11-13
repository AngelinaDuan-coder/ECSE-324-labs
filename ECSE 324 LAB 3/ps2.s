.equ PIXEL_BUFF, 0xC8000000
.equ CHAR_BUFF, 0xC9000000 
.equ PS2_DATA, 0xFF200100
//Linpei Duan, 260835863
.global _start

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
@ TODO: insert PS/2 driver here.
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
write_hex_digit:
        push    {r4, lr}
        cmp     r2, #9
        addhi   r2, r2, #55
        addls   r2, r2, #48
        and     r2, r2, #255
        bl      VGA_write_char_ASM
        pop     {r4, pc}
write_byte:
        push    {r4, r5, r6, lr}
        mov     r5, r0
        mov     r6, r1
        mov     r4, r2
        lsr     r2, r2, #4
        bl      write_hex_digit
        and     r2, r4, #15
        mov     r1, r6
        add     r0, r5, #1
        bl      write_hex_digit
        pop     {r4, r5, r6, pc}
input_loop:
        push    {r4, r5, lr}
        sub     sp, sp, #12
        bl      VGA_clear_pixelbuff_ASM
        bl      VGA_clear_charbuff_ASM
        mov     r4, #0
        mov     r5, r4
        b       .input_loop_L9
.input_loop_L13:
        ldrb    r2, [sp, #7]
        mov     r1, r4
        mov     r0, r5
        bl      write_byte
        add     r5, r5, #3
        cmp     r5, #79
        addgt   r4, r4, #1
        movgt   r5, #0
.input_loop_L8:
        cmp     r4, #59
        bgt     .input_loop_L12
.input_loop_L9:
        add     r0, sp, #7
        bl      read_PS2_data_ASM
        cmp     r0, #0
        beq     .input_loop_L8
        b       .input_loop_L13
.input_loop_L12:
        add     sp, sp, #12
        pop     {r4, r5, pc}
