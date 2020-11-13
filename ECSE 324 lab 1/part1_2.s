
.global _start
_start:
	MOV R0, #1 //xi
	MOV R1, #168 //a
	MOV R2, #100  //cnt
LOOP:
	CMP R2, #0 // compare counter and 0
	BEQ end
	MUL R3, R0, R0 // xi*xi
	SUB R3, R3, R1 //xi*xi-a
	MUL R3, R3, R0 //(xi*xi-a)*xi
	ASR R4, R3, #10 //R4:grad
	CMP R4, #2 // if grad>2
	MOVGT R4, #2
	CMP R4, #-2//if grad<2
	MOVLT R4, #-2
	SUBS R0, R0, R4// common process
	SUB R2, R2, #1
	B LOOP
end:
	B end
	
