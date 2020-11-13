
.global _start
.equ hex_displays_1, 0xFF200020//drives digits HEX3 to HEX0
.equ hex_displays_2, 0xFF200030//drives digits HEX5 and HEX4
.equ Timer_Port, 0xFFFEC600 //load of timer
_start:
	BL ARM_TIM_config_ASM
	B LOOP
LOOP:
	BL ARM_TIM_read_INT_ASM
	TST R0, #1 //F set to one when count ends
	BLNE COUNT
	TST R0, #1
	BLNE ARM_TIM_clear_INT_ASM
	B LOOP
COUNT:
	PUSH {R0,LR}
	MOV R7, #0 //initialize counter
	CMP R7, #15
	ADDLE R7,R7,#1 //increment counter if not reaching 15
	CMP R7, #15
	MOVGT R7,#0 //set to zero when over 15
	ADD R0,R7,#0
	BL HEX_write_ASM
	POP {R0, LR}
	BX LR
ARM_TIM_config_ASM:
	PUSH {R0,R1,R2,LR}
	LDR R1, =200000000 //down counter, 200MHz
	LDR R0, =Timer_Port
	STR R1, [R0] //initial count value in load register
	MOV R2, #7 //for E,I and A in control, all set to 1
	STR R2, [R0,#8] //store to control
	POP {R0,R1,R2,LR}
	BX LR
ARM_TIM_read_INT_ASM:
	PUSH {R3, R4, LR}
	LDR R4, =Timer_Port
	LDR R3, [R4,#12]  //interrupt status register
	TST R3, #1//F clears to zero by writing a 1
	MOVEQ R0, #0 //F value is 0x00000000
	TST R3, #1
	MOVNE R0, #1 //F value is 0x00000001
	POP {R3,R4,LR}
	BX LR
ARM_TIM_clear_INT_ASM:
	PUSH {R5,R6,LR}
	LDR R6, =Timer_Port
	MOV R5, #1
	STR R5, [R6,#12] //interrupt status register
	POP {R5,R6,LR}
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
	
	
	
	
