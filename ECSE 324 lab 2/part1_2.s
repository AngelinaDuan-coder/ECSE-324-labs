//Linpei Duan, 260835863
.global _start
.equ hex_displays_1, 0xFF200020//drives digits HEX3 to HEX0
.equ hex_displays_2, 0xFF200030//drives digits HEX5 and HEX4
.equ data_register, 0xFF200050
.equ inter_register, 0xFF200058
.equ edge_register, 0xFF20005C
.equ LED_MEMORY, 0xFF200000
.equ SW_MEMORY, 0xFF200040
_start:
	MOV R3, #0
	MOV R0, #0x0000000f//clear only last four bits, sum of 15
	BL HEX_clear_ASM
loop:
	BL read_slider_switches_ASM
	BL write_LEDs_ASM
	CMP R0, #512 //in switches
	MOVLT R0, #0x00000030
	BLLT HEX_flood_ASM
	BL read_slider_switches_ASM
	BL write_LEDs_ASM
	CMP R0, #512 //in push buttons
	MOVGE R0, #0x0000003f
	BLGE HEX_clear_ASM
	BL PB_edgecap_is_pressed_ASM
	CMP R0, #1
	PUSH {R3}
	BLEQ read_slider_switches_ASM
	BLEQ write_LEDs_ASM
	POP {R3}
	BLEQ HEX_write_ASM
	BLEQ PB_clear_edgecap_ASM
	MOVEQ R0, #0
	B loop

read_slider_switches_ASM:
    	LDR R3, =SW_MEMORY
    	LDR R0, [R3]
    	BX  LR
write_LEDs_ASM:
    	LDR R3, =LED_MEMORY
    	STR R0, [R3]
    	BX  LR
read_PB_data_ASM:
	PUSH {R2}
	LDR R2, =data_register
	LDR R0, [R2]
	POP {R2}
	BX LR
PB_data_is_pressed_ASM:
	PUSH {R1, R2}
	LDR R3, =data_register
	LDR R2, [R1]
	POP {R1, R2}
	BX LR 
read_PB_edgecp_ASM:
	PUSH {R2}
	LDR R2, =edge_register
	LDR R1, [R2]
	STR R1, [R2]
	POP {R2}
	BX LR
PB_edgecap_is_pressed_ASM:
	PUSH {R3, R2}
	LDR R3, =edge_register
	LDR R1, [R3]
	CMP R1, #0
	MOVGT R0, #1
	POP {R3, R2}
	BX LR
PB_clear_edgecap_ASM:
	PUSH {R1, R2}
	LDR R1, =edge_register
	MOV R2, #1
	STR R2, [R1]
	POP {R1, R2}
	BX LR
enable_PB_INT_ASM:
	PUSH {R1, R2}
	LDR R1, =inter_register
	MOV R2, #3
	STR R2, [R1, #8]
	POP {R1, R2}
	BX LR
disable_PB_INT_ASM:
	PUSH {R1, R2}
	LDR R1, =inter_register
	MOV R2, #3
	STR R2, [R1, #8]
	POP {R1, R2}
	BX LR 
HEX_clear_ASM:
	//Algorithm: F:doesn't matter; 0:set to zero. R0 has 8 bytes(32-bit data) and 7 bits for each hex
	PUSH {R1-R7}
	LDR R1, =hex_displays_1 //hex3-0
	LDR R2, =hex_displays_2 //hex5 and hex4
	MOV R3, #1
	MOV R7, #0 //counter
	B before_clear
before_clear:
	CMP R7, #5
	BGT Exit_clear
	CMP R0,R3
	BEQ clear
	B clear_ends
clear:
	LDR R4, [R1]//read from the data register hex3-0
	
	CMP R0,#1 //TST is a bitwise and operation. Bitwise and R0 and 00000001
	ANDEQ R4, R4, #0xFFFFFF00//TST returns 1->NE(not equal to 0); set last two bytes to 0;hex0 clears
	STREQ R4,[R1]//store data in memory
	
	CMP R0,#2 
	ANDEQ R4,R4, #0xFFFF00FF//hex1 clears
	STREQ R4,[R1]
	
	CMP R0,#4
	ANDEQ R4,R4, #0xFF00FFFF//hex2 clears
	STREQ R4, [R1]
	
	CMP R0,#8
	ANDEQ R4,R4, #0x00FFFFFF//hex3 clears
	STREQ R4, [R1]
	
	CMP R0,#16
	LDREQ R4,[R2] //load the second display which is for hex 4 and 5
	ANDEQ R4,R4, #0xFFFFFF00//hex4 clears
	STREQ R4, [R2]
	
	CMP R0,#32
	LDREQ R4, [R2]
	ANDEQ R4,R4,#0xFFFF00FF
	STREQ R4, [R2]
clear_ends:
	LSL R3,#1
	ADD R7,R7,#1
	B before_clear
Exit_clear:
	POP {R1-R7}
	BX LR
HEX_flood_ASM:
	//Algorithm: F:all on 0: doesn't matter
	PUSH {R1-R7}
	LDR R1, =hex_displays_1
	LDR R2, =hex_displays_2
	MOV R3, #1
	MOV R7, #0
before_flood:
	CMP R7, #5
	BGT Exit_flood
	CMP R0,R3
	BEQ flood
	B flood_ends
flood:
	LDR R4,[R1]
	
	CMP R6,#1 
	ORREQ R4, R4, #0x000000FF//hex0 floods
	STREQ R4,[R1]

	CMP R6, #2
	ORREQ R4,R4, #0x0000FF00//hex1 floods
	STREQ R4,[R1]

	CMP R6, #4
	ORREQ R4, R4, #0x00FF0000//hex2 floods
	STREQ R4,[R1]
	
	CMP R6,#8
	ORREQ R4,R4,#0xFF000000//hex3 floods
	STREQ R4,[R1]

	CMP R6,#16
	LDREQ R4,[R2]
	ORREQ R4,R4,#0x000000FF//hex4 floods
	STREQ R4,[R2]
	
	CMP R0,#32
	LDREQ R4,[R2]
	ORREQ R4,R4,#0x0000FF00//hex5 floods
	STREQ R4,[R2]
flood_ends:
	LSL R3,#1
	ADD R7,R7,#1
	B before_flood
Exit_flood:
	POP {R1-R7}
	BX LR
	
HEX_write_ASM:      
	PUSH {R1-R10}      
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

	POP {R1-R10}
    BX LR
	
end:
B end
	