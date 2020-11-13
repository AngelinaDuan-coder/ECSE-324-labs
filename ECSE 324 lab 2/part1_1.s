
.global _start
.equ LED_MEMORY, 0xFF200000
.equ SW_MEMORY, 0xFF200040
_start:
LOOP:
BL read_slider_switches_ASM
BL write_LEDs_ASM
B LOOP
// Sider Switches Driver
// returns the state of slider switches in R0
/* The EQU directive gives a symbolic name to a numeric constant,
a register-relative value or a PC-relative value. */
read_slider_switches_ASM:
    LDR R1, =SW_MEMORY
    LDR R0, [R1]
    BX  LR
// LEDs Driver
// writes the state of LEDs (On/Off state) in R0 to the LEDs memory location
write_LEDs_ASM:
    LDR R1, =LED_MEMORY
    STR R0, [R1]
    BX  LR	
