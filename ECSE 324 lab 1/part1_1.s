//Linpei Duan, 260835863
.global _start
_start:
	MOV R0, #1 //xi
	MOV R1, #168 //a
	MOV R2, #100  //cnt
	MOV R5, #0 //i
LOOP:
	CMP R5, R2 // compare counter and i
	BGE end //i>=counter end
	MUL R3, R0, R0 // xi*xi
	SUB R3, R3, R1 //xi*xi-a
	MUL R3, R3, R0 //(xi*xi-a)*xi
	ASR R4, R3, #10 //R4:step
	CMP R4, #2 // if step>2
	MOVGT R4, #2
	CMP R4, #-2//if step<-2
	MOVLT R4, #-2
	SUBS R0, R0, R4// common process
	ADD R5, R5, #1
	B LOOP
end:
	B end
