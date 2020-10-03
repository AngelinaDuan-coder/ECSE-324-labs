//Linpei Duan, 260835863
n: .word 5
array: .word 4,2,1,4,-1
.global _start
_start:
	LDR R0, =n//address of n
	LDR R1, [R0] //load size
	ADD R2, R0, #4 //pointer to the first element of the array
	LDR R3, [R2] //r4 is the value of the first element
	MOV R4, #0 //i
	MOV R5, #0 //j
	MOV R6, #0 //tmp
	MOV R7, #0 //cur_min_idx
bigloop:
	SUB R8, R1, #1 //R8:n-1
	CMP R4, R8
	BGE end
	LDR R6, [R2, R4, LSL#2] //R6:tmp
	ADD R7, R4, #0 //R7:cur_min_idx
	ADD R5, R4, #1 //j=i+1
	B smallloop
smallloop:
	CMP R5, R1
	BGE swap
	LDR R9, [R2, R5, LSL#2] //R9:*(ptr+j)
	CMP R6, R9
	BLE increment
	LDR R6, [R2, R5, LSL#2] //tmp=*(ptr+j)
	ADD R7, R5, #0
	B increment
swap:
	LDR R10, [R2, R4, LSL#2] //R10:tmp
	LDR R11, [R2, R7, LSL#2] //*(ptr+cur_min_idx)
	STR R10, [R2, R7, LSL#2]
	STR R11, [R2, R4, LSL#2]
	ADD R4, R4, #1
	B bigloop
increment:
	ADD R5, R5, #1
	B smallloop
end:
	B end
	
	