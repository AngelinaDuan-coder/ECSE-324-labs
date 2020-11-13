
n: .word 4
array: .word 3,4,5,4
.global _start
_start:
	MOV R0, #0 //mean
	MOV R1, #0 //log2_n
	LDR R2, =n //address of n
	LDR R3, [R2] //load size
	ADD R4, R2, #4 //point to the first element of the array
	MOV R5, #1 //for 1<< log2_n
	MOV R6, #0 //store each element of the array
	MOV R7, #0 //first i
	MOV R8, #0 //second i
while:// this is the while
	LSL R6, R5, R1 // 1<< log2_n (R1)
	CMP R6, R3
	BGE firstloop
	ADD R1, R1, #1 //log2_n ++
	B while
firstloop://calculate the mean of the given array
	LDR R6, [R4] //r6 is the value of the first element
	CMP R7, R3
	BGE meanshift
	ADD R0, R0, R6 //mean += *ptr
	ADD R4, R4, #4 //ptr++
	ADD R7, R7, #1 //i++
	B firstloop
meanshift:
	LSR R0, R0, R1
	ADD R4, R2, #4 //pointer points to the first element of the array
	B secondloop
secondloop://calculate the given array
	LDR R6, [R4]
	CMP R8, R3
	BGE end
	SUB R6, R6, R0 //*ptr -= mean
	STR R6, [R4]
	ADD R4, R4, #4 //ptr++
	ADD R8, R8, #1 //i++
	B secondloop
end: 
	B end
	
	

	
	

	
