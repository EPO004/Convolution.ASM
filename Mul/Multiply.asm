segment .data ; define our matrices and variables and formats

A resd 128      ; float A[8][8]
B resd 128      ; float B[8][8]
C resd 128      ; float c[8][8]
n dd 0          ; define variable n as int 32
max dd 60000000 ; its for computing the time of multiply in order 10e7
read_int_format:    db "%d"   , 0 ; format to scan
print_int_format:   db "%d"   , 0 ; format to print
read_float_format:  db "%f"   , 0 ; format to scan
print_float_format: db "%.2f ", 0 ; format to print

segment .text ; extern some C function like printf, scanf and ...
    global main
    extern printf
    extern putchar
    extern puts
    extern scanf
    extern getchar

read_int: ; for get input as int
    sub rsp, 8
    mov rsi,rsp
    mov rdi, read_int_format ; move int format to read in rdi
    mov rax, 1
    call scanf ; scan input
    mov eax,[rsp] ; move input into eax
    add rsp, 8
    ret

read_float: ; for get input as float
    sub rsp, 8

    mov rsi, rsp 
    mov rdi, read_float_format ; move float format to read in rdi
    mov rax, 1
    call scanf ; scan input
    movss xmm0,[rsp] ; move input into xmm0
    add rsp, 8
    ret 

 print_float: ; for print the result as flaot 
	sub	rsp, 8
	cvtss2sd xmm0, xmm0 ; convert the result that stored in xmm0 to be printable
	mov	rdi,print_float_format ; move float format to print in rdi
	mov	rax, 1
	call printf
	add	rsp, 8
	ret    
   
main:
    sub rsp, 8
    call read_int ; get the size of matrix
    mov [n], eax ;copy the input as int to n
    ;we define r14d as  (i) and r13d as (j) in a matrix form
    xor r14d, r14d ; int i = 0

; input matrix A
INPUT1_LOOP1: ; this loop is for the counter i that show the row of matrix A
    mov eax, [n] ; copy value of n into eax to compare later
    cmp eax, r14d ; do eax - r14d to make a jump if needed
    jle INPUT1_ENDLOOP1 ;if n <= i break and jump end of loop to do rest of code
    xor r13d, r13d ; int j = 0
INPUT1_LOOP2: ; this loop is for the counter j that show the column of matrix B
    mov eax, [n] ; copy value of n into eax to compare later
    cmp eax,r13d ; do eax - r13d to make a jump if needed
    jle INPUT1_ENDLOOP2 ;if n<=j break and jump end of loop to do rest of code

    call read_float ; get each element of matrix and copy input in xmm0 ( A[i][j] : A[8*i + j])
    mov ecx, r14d ; copy the value of i counter in ecx
    sal ecx, 3 ; i << 3 : mul 2^3=8 so why? we have A[i][j] and its size is A[8][8] so: A[i][j] = A[i*8+j]
    add ecx, r13d   ; add j to i  
    sal ecx, 2 ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    movss A[ecx], xmm0 ; it does A[i][j] = value of xmm0

    inc r13d ; j++
    jmp INPUT1_LOOP2 ; does the loop again
INPUT1_ENDLOOP2: 

    inc r14d ; i++
    jmp INPUT1_LOOP1 ; does the loop again

INPUT1_ENDLOOP1: 


;input matrix B
xor r14d, r14d ;int i = 0
INPUT2_LOOP1: ; this loop is for the counter i that show the row of matrix B
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,r14d ; do eax - r14d to make a jump if needed
    jle INPUT2_ENDLOOP1 ;if n <= i break and jump end of loop to do rest of code
    xor r13d,r13d ; int j=0
INPUT2_LOOP2: ; this loop is for the counter j that show the column of matrix B
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,r13d ; do eax - r13d to make a jump if needed
    jle INPUT2_ENDLOOP2 ;if n<=j break and jump end of loop to do rest of code

    call read_float; get each element of matrix and copy input in xmm0 ( B[i][j] )
    mov ecx, r14d ;; copy the value of i counter in ecx
    sal ecx, 3 ; i << 3 : mul 2^3=8 so why? we have B[i][j] and its size is B[8][8] so: B[i][j] = B[i*8+j]
    add ecx, r13d     ; add j to i  
    sal ecx, 2 ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    movss B[ecx], xmm0 ; it does B[i][j] = value of xmm0

    inc r13d ;j++
    jmp INPUT2_LOOP2 ; does the loop again
INPUT2_ENDLOOP2:
    inc r14d ;i++
    jmp INPUT2_LOOP1 ; does the loop again

INPUT2_ENDLOOP1: 
xor ebx, ebx ; it does the loop for count max to compute time better
LOOP1:

    ; C[i][j] += A[i][k] * B[k][j];    
    xor r13d, r13d ; int i = 0
MUL_LOOP1: ; this loop is for i
    mov eax,[n] ; copy size of matrix in eax
    cmp eax,r13d ; compare eax , r13d to jump if needed
    jle MUL_ENDLOOP1 ; if n<=i break and run rest of code
    xor r14d,r14d ; int j = 0
MUL_LOOP2: ; this loop is for j
    mov eax,[n] ; copy size of matrix in eax
    cmp eax,r14d ; compare eax , r14d to jump if needed
    jle MUL_ENDLOOP2 ; if n<=j break and run rest of code

    xor r15d, r15d ; int k = 0
    pxor xmm0, xmm0 ; define temp sum for each element of C[i][j] as 0 to sum all multiplys
MUL_LOOP3: ; this loop is for k
    mov eax,[n] ; copy size of matrix in eax
    cmp eax,r15d ; compare eax , r15d to jump if needed
    jle MUL_ENDLOOP3 ;if n<=j break

    ;to load the value of A[i][k]
    mov ecx, r13d    
    sal ecx, 3 ; i << 3 : to find the value A[8*i + k]
    add ecx, r15d     
    sal ecx, 2 ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    movss xmm1, A[ecx] ; load the value of A[i][k] into xmm1

    ;to load the value of B[k][j] and multiply it by A[i][k]
    mov ecx, r15d    
    sal ecx, 3 ; k << 3 : to find the value B[k*8 + j]
    add ecx, r14d     
    sal ecx, 2 ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    mulss xmm1,B[ecx] ; multiply B[k][j] by A[i][k] and store the result in xmm1
    addss xmm0, xmm1 ; add xmm1 to last sum of multiplys in xmm0

    inc r15d ; k++
    jmp MUL_LOOP3 ; does loop again
MUL_ENDLOOP3: 

    mov ecx, r13d ;
    sal ecx, 3 ; i << 3 : to store the sum in C[i*8 + j]
    add ecx, r14d     
    sal ecx, 2 ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    movss C[ecx], xmm0  ; copy the result of multiply A[i][::] and B[::][j] into C [i][j]

    inc r14d ; j++
    jmp MUL_LOOP2 ; does loop again

MUL_ENDLOOP2:

    inc r13d ; i++
    jmp MUL_LOOP1 ; does loop again

MUL_ENDLOOP1: 
inc ebx ; incerement the counter of time computing
cmp ebx, [max] ; compare the result with max value to do the loop for time again
jle LOOP1


; to print the result of A @ B = C
xor r14d, r14d ; int i = 0
OUTPUT_LOOP1:
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,r14d ; do eax - r14d to make a jump if needed
    jle OUTPUT_ENDLOOP1 ;if n<=i break
    xor r13d,r13d ; int j=0
OUTPUT_LOOP2:
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,r13d ;  do eax - r13d to make a jump if needed
    jle OUTPUT_ENDLOOP2 ;if n<=j break

    mov ecx, r14d ;
    sal ecx, 3 ; i << 3 : to find the value of C[i*8 + j] to print it
    add ecx, r13d     
    sal ecx, 2 ; ; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
    movss xmm0, C[ecx] ; load and get C[i][j] into xmm0 to print it
    call print_float ; print each element of matrix as float


    inc r13d ; j++
    jmp OUTPUT_LOOP2
OUTPUT_ENDLOOP2:
    mov edi, 10 ; move the ASCII code of \n into edi
    call putchar ; print \n
    inc r14d ; i++
    jmp OUTPUT_LOOP1

OUTPUT_ENDLOOP1: 

    add rsp, 8
    ret
