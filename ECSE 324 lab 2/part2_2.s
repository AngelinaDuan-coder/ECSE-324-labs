
.global _start
.equ hex_displays_1, 0xFF200020//drives digits HEX3 to HEX0
.equ hex_displays_2, 0xFF200030//drives digits HEX5 and HEX4
.equ Timer_Port, 0xFFFEC600 //load of timer
.equ edge_register, 0xFF20005C
_start:
//stopwatch should be able to count in increments of 10 milliseconds
	LDR R2,=Timer_Port
	MOV R1, #6//E=0,timer not start,initialize timer
	STR R1, [R2,#8] //Control
	MOV R0,#0
	MOV R2,#0
	MOV R3,#0 
	MOV R4,#0
	MOV R5,#0
	MOV R6,#0
	MOV R7,#0
	MOV R8,#0
	B LOOP
LOOP:
//PB0, PB1, and PB2 will be used to start, stop and reset the stopwatch, respectively
	BL PB_edgecap_is_pressed_ASM
	CMP R0, #1
	BLNE ARM_TIM_clear_INT_ASM
	BLEQ Timer_CONTROL
	BL ARM_TIM_read_INT_ASM //read F
	//reset clock
	CMP R0,#1
	BLEQ CLOCK_FIRST 
	CMP R0,#1 //F=1 when counter ends
	BLEQ ARM_TIM_clear_INT_ASM
	B LOOP
PB_edgecap_is_pressed_ASM:
	PUSH {R1,R2}
	LDR R1, =edge_register
	LDR R2, [R1]
	STR R2, [R1]
	CMP R2, #0
	MOVGT R0, #1 //corrresponding bit changes from 0 to 1
	POP {R1,R2}
	BX LR
ARM_TIM_clear_INT_ASM:
	PUSH {R1,R2,LR}
	LDR R1, =Timer_Port
	MOV R2, #1
	STR R2, [R1,#12] //interrupt status register
	POP {R1,R2,LR}
	BX LR
Timer_CONTROL:
	PUSH {R1,R2,LR}
	LDR R2, =Timer_Port
	TST R1, #1
	BLNE ARM_TIM_config_ASM//E=1
	TST R1, #2
	BLNE RESET_CONTROL//reset all to 1
	TST R1, #4
	BLNE RESET_CONTROL//reset all to 1
	MOVNE R0,#0
	MOVNE R1, #63//write 0 to all hex displays(initialize)
	BLNE HEX_write_ASM
	BLNE ARM_TIM_config_ASM	
	POP {R1,R2,LR}
	BX LR
RESET_CONTROL:
	PUSH {R1,R2}
	LDR R2,=Timer_Port
	MOV R1,#6
	STR R1,[R2,#8]
	POP {R1,R2}
	BX LR
ARM_TIM_read_INT_ASM:
	PUSH {R1, R2, LR}
	LDR R1, =Timer_Port
	LDR R2, [R1,#12]  //interrupt status register
	CMP R2, #1//F clears to zero by writing a 1
	MOVNE R0, #0 //F value is 0x00000000
	CMP R2, #1
	MOVEQ R0, #1 //F value is 0x00000001
	POP {R1,R2,LR}
	BX LR
ARM_TIM_config_ASM:
	PUSH {R1,R2,R3,LR}
	LDR R2, =#500000 
	LDR R3, =Timer_Port
	STR R2, [R3] //initial count value in load register
	MOV R1, #7 //for E,I and A in control, all set to 1
	STR R1, [R3,#8] //store to control
	POP {R1,R2,R3,LR}
	BX LR
CLOCK_FIRST:
	PUSH {LR}
	ADD R9,R9,#1
	ADD R3,R9,#0
CLOCK:
	//Display milliseconds on HEX1-0, seconds on HEX3-2, and minutes on HEX5-4
	//minutes
	CMP R7,#10
	ADDGE R8,R8,#1
	CMP R7,#10
	SUBGE R7,R7,#10
	CMP R7,#10
	BGE CLOCK
	//seconds
	CMP R6,#6 //60s=1min
	ADDGE R7,R7,#1
	CMP R6,#6
	SUBGE R6,R6,#6
	CMP R6,#6
	BGE CLOCK
	
	CMP R5,#10
	ADDGE R6,R6,#1
	CMP R5,#10
	SUBGE R5,R5,#10
	CMP R5,#10
	BGE CLOCK
	//milliseconds
	CMP R4,#10
	ADDGE R5,R5,#1
	CMP R4,#10
	SUBGE R4,R4,#10
	CMP R4,#10
	BGE CLOCK
	
	CMP R3, #10
	ADDEQ R4,R4,#1
	CMP R3, #10
	SUBGE R3,R3,#10 //reset to 0
	CMP R3,#10
	BGE CLOCK
	
	//milliseconds
	ADD R0,R3,#0
	MOV R1,#1
	BL HEX_write_ASM
	
	ADD R0,R4,#0
	MOV R1,#2
	BL HEX_write_ASM
	//seconds
	ADD R0,R5,#0
	MOV R1,#4
	BL HEX_write_ASM
	
	ADD R0,R6,#0
	MOV R1,#8
	BL HEX_write_ASM
	//minutes
	ADD R0,R7,#0
	MOV R1,#16
	BL HEX_write_ASM
	
	ADD R0,R8,#0
	MOV R1,#32
	BL HEX_write_ASM
	MOV R1,#0
	POP {LR}
	BX LR

HEX_write_ASM:      
		PUSH {R1-R7}      
		LDR R2, =hex_displays_1    
    	LDR R3, =hex_displays_2    
		MOV R4, #1                        
    	MOV R5, #0            

display_to_Hex:     
		CMP R0, #0        //0
		MOVEQ R5, #0x3F    
    	CMP R0, #1        //1
    	MOVEQ R5, #0x6
    	CMP R0, #2        //2
   		MOVEQ R5, #0x5B
    	CMP R0, #3        //3
    	MOVEQ R5, #0x4F
    	CMP R0, #4        //4
    	MOVEQ R5, #0x66
    	CMP R0, #5        //5
    	MOVEQ R5, #0x6D
    	CMP R0, #6        //6
    	MOVEQ R5, #0x7D
    	CMP R0, #7        //7
    	MOVEQ R5, #0x7
    	CMP R0, #8        //8
    	MOVEQ R5, #0x7F
    	CMP R0, #9        //9
    	MOVEQ R5, #0x67
    	CMP R0, #10       //A
    	MOVEQ R5, #0x77
    	CMP R0, #11       //B
		MOVEQ R5, #0x7C
    	CMP R0, #12       //C
    	MOVEQ R5, #0x39
    	CMP R0, #13       //D
		MOVEQ R5, #0x5E
    	CMP R0, #14       // E
    	MOVEQ R5, #0x79
    	CMP R0, #15       // F
    	MOVEQ R5, #0x71
WRITE:             
		LDR R7, [R2]
		CMP R1, #1
		ANDEQ R7, R7, #0xFFFFFF00
    	ADDEQ R7, R7, R5, LSL #0
		STREQ R7, [R2]
					
    	CMP R1, #2
    	ANDEQ R7, R7, #0xFFFF00FF
    	ADDEQ R7, R7, R5, LSL #8
		STREQ R7, [R2]
					
    	CMP R1, #4
    	ANDEQ R7, R7, #0xFF00FFFF
    	ADDEQ R7, R7, R5, LSL #16
		STREQ R7, [R2]
					
    	CMP R1, #8
    	ANDEQ R7, R7, #0x00FFFFFF
    	ADDEQ R7, R7, R5, LSL #24
		STREQ R7, [R2]
					
    	CMP R1, #16
		LDREQ R7, [R3]
    	ANDEQ R7, R7, #0xFFFFFF00
    	ADDEQ R7, R7, R5, LSL #0
		STREQ R7, [R3]
					
		CMP R1, #32
		LDREQ R7, [R3]
    	ANDEQ R7, R7, #0xFFFF00FF
   		ADDEQ R7, R7, R5, LSL #8
    	STREQ R7, [R3]        

		POP {R1-R7}
    	BX LR
end:
B end
