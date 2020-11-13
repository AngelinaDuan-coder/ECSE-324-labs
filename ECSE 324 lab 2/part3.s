
.section .vectors, "ax"
B _start
B SERVICE_UND       // undefined instruction vector
B SERVICE_SVC       // software interrupt vector
B SERVICE_ABT_INST  // aborted prefetch vector
B SERVICE_ABT_DATA  // aborted data vector
.word 0 // unused vector
B SERVICE_IRQ       // IRQ interrupt vector
B SERVICE_FIQ       // FIQ interrupt vector
.text
PB_int_flag :
    .word 0x0
tim_int_flag :
    .word 0x0
.global _start
_start:
//timer
.equ Timer_LOAD, 0xFFFEC600
.equ Timer_CONTROL,0xFFFEC608
.equ Timer_INTERRUPT, 0xFFFEC60C
//push button
.equ data_register, 0xFF200050
.equ inter_register, 0xFF200058
.equ edge_register, 0xFF20005C
.equ hex_displays_1, 0xFF200020//drives digits HEX3 to HEX0
.equ hex_displays_2, 0xFF200030//drives digits HEX5 and HEX4

    /* Set up stack pointers for IRQ and SVC processor modes */
    MOV        R1, #0b11010010      // interrupts masked, MODE = IRQ
    MSR        CPSR_c, R1           // change to IRQ mode
    LDR        SP, =0xFFFFFFFF - 3  // set IRQ stack to A9 onchip memory
    /* Change to SVC (supervisor) mode with interrupts disabled */
    MOV        R1, #0b11010011      // interrupts masked, MODE = SVC
    MSR        CPSR, R1             // change to supervisor mode
    LDR        SP, =0x3FFFFFFF - 3  // set SVC stack to top of DDR3 memory
    BL     CONFIG_GIC           // configure the ARM GIC
	BL enable_PB_INT_ASM
	BL ARM_TIM_config_ASM
    // To DO: write to the pushbutton KEY interrupt mask register
    // Or, you can call enable_PB_INT_ASM subroutine from previous task
    // to enable interrupt for ARM A9 private timer, use ARM_TIM_config_ASM subroutine
    LDR        R0, =0xFF200050      // pushbutton KEY base address
    MOV        R1, #0xF             // set interrupt mask bits
    STR        R1, [R0, #0x8]       // interrupt mask register (base + 8)
    // enable IRQ interrupts in the processor
    MOV        R0, #0b01010011      // IRQ unmasked, MODE = SVC
initialize:
	MOV R3, #0
	MOV R4, #0
	MOV R5, #0
	MOV R6, #0
	MOV R7, #0
	MOV R8, #0
	MOV R9, #0
	MOV R10, #0
     MSR        CPSR_c, R0
	MOV R0, #0
FLAG: 
	LDR R2, =PB_int_flag
	LDR R0, [R2]
	TST R0, #1
	BEQ FLAG
IDLE:
	LDR R2, =PB_int_flag //see which PB is pushed
	LDR R0, [R2]
	//stop
	CMP R0, #2
	BEQ IDLE
	//reset
	CMP R0, #4
	MOVEQ R3, #0
	MOVEQ R4, #0
	MOVEQ R5, #0
	MOVEQ R6, #0
	MOVEQ R7, #0
	MOVEQ R8, #0
	MOVEQ R9, #0
	CMP R0, #4
	PUSH {R0}
	MOVEQ R0, #0
	STREQ R0, [R2]
	MOVEQ R1, #63
	BLEQ HEX_write_ASM
	POP {R0}
	CMP R0, #1
	BEQ CLOCK_FIRST
CLOCK_FIRST:
	LDR R2, =tim_int_flag
	LDR R0, [R2]
	MOV R2, #0
	CMP R0, #1
	BNE IDLE
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
	PUSH {R0}
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
	POP {R0}
	MOV R1,#0
	LDR R2, =tim_int_flag
	LDR R0, [R2]
	CMP R0, #2
	MOVGE R0, #0
	STRGE R0, [R2]
	CMP R0, #1
	MOVEQ R0, #0
	STREQ R0, [R2]
    B IDLE // This is where you write your objective task
	/*--- Undefined instructions ---------------------------------------- */
SERVICE_UND:
    B SERVICE_UND
/*--- Software interrupts ------------------------------------------- */
SERVICE_SVC:
    B SERVICE_SVC
/*--- Aborted data reads -------------------------------------------- */
SERVICE_ABT_DATA:
    B SERVICE_ABT_DATA
/*--- Aborted instruction fetch ------------------------------------- */
SERVICE_ABT_INST:
    B SERVICE_ABT_INST
/*--- IRQ ----------------------------------------------------------- */
SERVICE_IRQ:
    PUSH {R1-R7, LR}
/* Read the ICCIAR from the CPU Interface */
    LDR R4, =0xFFFEC100
    LDR R5, [R4, #0x0C] // read from ICCIAR

/* To Do: Check which interrupt has occurred (check interrupt IDs)
   Then call the corresponding ISR
   If the ID is not recognized, branch to UNEXPECTED
   See the assembly example provided in the De1-SoC Computer_Manual on page 46 */

Timer_check:
	CMP R5,#29
	BNE Pushbutton_check	
	BL ARM_TIM_ISR
	B EXIT_IRQ
Pushbutton_check:
    CMP R5, #73
UNEXPECTED:
    BNE UNEXPECTED      // if not recognized, stop here
    BL KEY_ISR
EXIT_IRQ:
/* Write to the End of Interrupt Register (ICCEOIR) */
    STR R5, [R4, #0x10] // write to ICCEOIR
    POP {R1-R7, LR}
SUBS PC, LR, #4
/*--- FIQ ----------------------------------------------------------- */
SERVICE_FIQ:
    B SERVICE_FIQ
CONFIG_GIC:
    PUSH {LR}
/* To configure the FPGA KEYS interrupt (ID 73):
* 1. set the target to cpu0 in the ICDIPTRn register
* 2. enable the interrupt in the ICDISERn register */
/* CONFIG_INTERRUPT (int_ID (R0), CPU_target (R1)); */
/* To Do: you can configure different interrupts
   by passing their IDs to R0 and repeating the next 3 lines */
    MOV R0, #73            // KEY port (Interrupt ID = 73)
    MOV R1, #1             // this field is a bit-mask; bit 0 targets cpu0
    BL CONFIG_INTERRUPT
	MOV R0, #29            
    MOV R1, #1             
    BL CONFIG_INTERRUPT

/* configure the GIC CPU Interface */
    LDR R0, =0xFFFEC100    // base address of CPU Interface
/* Set Interrupt Priority Mask Register (ICCPMR) */
    LDR R1, =0xFFFF        // enable interrupts of all priorities levels
    STR R1, [R0, #0x04]
/* Set the enable bit in the CPU Interface Control Register (ICCICR).
* This allows interrupts to be forwarded to the CPU(s) */
    MOV R1, #1
    STR R1, [R0]
/* Set the enable bit in the Distributor Control Register (ICDDCR).
* This enables forwarding of interrupts to the CPU Interface(s) */
    LDR R0, =0xFFFED000
    STR R1, [R0]
    POP {PC}

/*
* Configure registers in the GIC for an individual Interrupt ID
* We configure only the Interrupt Set Enable Registers (ICDISERn) and
* Interrupt Processor Target Registers (ICDIPTRn). The default (reset)
* values are used for other registers in the GIC
* Arguments: R0 = Interrupt ID, N
* R1 = CPU target
*/
CONFIG_INTERRUPT:
    PUSH {R4-R5, LR}
/* Configure Interrupt Set-Enable Registers (ICDISERn).
* reg_offset = (integer_div(N / 32) * 4
* value = 1 << (N mod 32) */
    LSR R4, R0, #3    // calculate reg_offset
    BIC R4, R4, #3    // R4 = reg_offset
    LDR R2, =0xFFFED100
    ADD R4, R2, R4    // R4 = address of ICDISER
    AND R2, R0, #0x1F // N mod 32
    MOV R5, #1        // enable
    LSL R2, R5, R2    // R2 = value
/* Using the register address in R4 and the value in R2 set the
* correct bit in the GIC register */
    LDR R3, [R4]      // read current register value
    ORR R3, R3, R2    // set the enable bit
    STR R3, [R4]      // store the new register value
/* Configure Interrupt Processor Targets Register (ICDIPTRn)
* reg_offset = integer_div(N / 4) * 4
* index = N mod 4 */
    BIC R4, R0, #3    // R4 = reg_offset
    LDR R2, =0xFFFED800
    ADD R4, R2, R4    // R4 = word address of ICDIPTR
    AND R2, R0, #0x3  // N mod 4
    ADD R4, R2, R4    // R4 = byte address in ICDIPTR
/* Using register address in R4 and the value in R2 write to
* (only) the appropriate byte */
    STRB R1, [R4]
    POP {R4-R5, PC}
KEY_ISR:
	PUSH {R1-R3}
	LDR R1, =data_register
	LDR R2, =PB_int_flag
	LDR R0, [R1,#12]
	STR R0, [R1,#12]
	STR R0, [R2]
	CMP R0, #0
	MOVNE R2, #1
	STRNE R2, [R1,#12]
	LDR R2, =PB_int_flag
	LDR R3, [R2]
	POP {R1-R3}
	BX LR
CHECK_KEY0:
    MOV R3, #0x1
    ANDS R3, R3, R1        // check for KEY0
    BEQ CHECK_KEY1
    MOV R2, #0b00111111
    STR R2, [R0]           // display "0"
    B END_KEY_ISR
CHECK_KEY1:
    MOV R3, #0x2
    ANDS R3, R3, R1        // check for KEY1
    BEQ CHECK_KEY2
	PUSH {R1,R2}
	LDR R1, =Timer_LOAD
	MOV R2, #6
	STR R2, [R1, #8]
	POP {R1,R2}
    B END_KEY_ISR
CHECK_KEY2:
    MOV R3, #0x4
    ANDS R3, R3, R1        // check for KEY2
    BEQ IS_KEY3
    MOV R2, #0b01011011
    STR R2, [R0]           // display "2"
    B END_KEY_ISR
IS_KEY3:
    MOV R2, #0b01001111
    STR R2, [R0]           // display "3"
END_KEY_ISR:
    BX LR
ARM_TIM_ISR:
	PUSH {R0-R3}
	LDR R3, =tim_int_flag
	LDR R1, =Timer_LOAD
	LDR R2, [R1,#12]
	CMP R2, #1
	MOVEQ R0, #1
	STREQ R0, [R3]
	STREQ R0, [R1,#12]
	pop {R0-R3}
	BX LR
enable_PB_INT_ASM:
	PUSH {R1, R2}
	LDR R1, =data_register
	MOV R2, #3
	STR R2, [R1, #8]
	POP {R1, R2}
	BX LR
ARM_TIM_config_ASM:
	PUSH {R0,R1,R2,LR}
	LDR R1, =#2000000 //down counter
	LDR R0, =Timer_LOAD
	STR R1, [R0] //initial count value in load register
	MOV R2, #7 //for E,I and A in control, all set to 1
	STR R2, [R0,#8] //store to control
	POP {R0,R1,R2,LR}
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
