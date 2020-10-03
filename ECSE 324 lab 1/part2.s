//Linpei Duan, 260835863
n: .word 4
array: .word 5,6,7,8
.global _start
_start:
	LDR R2, =n //address of n
	LDR R4, [R2] // load size
	ADD R3, R2, #4 // point to the first element of the array
	//R3 is the pointer
	MOV R0, #0 // log2_n
	MOV R5, #0 //i
	MOV R6, #0 //tmp
	MOV R1, #0 //store what pointer points to
	MOV R7, #1 // for 1<<log2_n
while:// this is the while
	LSL R1, R7, R0 // 1<< log2_n (R1)
	CMP R1, R4
	BGE LOOP
	ADD R0, R0, #1 //log2_n ++
	B while
LOOP:// this is the for loop
	LDR R1, [R3] //load the value of the first element of the array
	CMP R5, R4 //compare i and n
	BGE norm // goes to the outside of the loop
	MUL R1, R1, R1 //(*ptr)*(*ptr)
	ADD R6, R6, R1 //tmp+=(*ptr)*(*ptr), R8:temp
	ADD R3, R3, #4 //ptr++
	ADD R5, R5, #1 //i++
	B LOOP
norm:	
	LSR R6, R6, R0 //tmp=tmp>> log2_n
iter://sqrtIter
	MOV R0, #1 //norm
	MOV R2, #100  //cnt
	MOV R5, #0 //i
	MOV R4, #0 //step
iterloop:
	CMP R5, R2 // compare counter and i
	BGE end //i>=counter end
	MUL R3, R0, R0 // norm*norm
	SUB R3, R3, R6 //norm*norm-tmp
	MUL R3, R3, R0 //(norm*norm-tmp)*norm
	ASR R4, R3, #10 //R4:step
	CMP R4, #2 // if step>2
	MOVGT R4, #2
	CMP R4, #-2//if step<-2
	MOVLT R4, #-2
	SUBS R0, R0, R4// common process
	ADD R5, R5, #1
	B iterloop
end:
	B end
	
	