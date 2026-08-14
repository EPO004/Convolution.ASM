segment .data ; define our matrices and variables and formats

image	   resd	    8388608	; float matrix[2048][2048] 
kernel     resd     128  ;float matrix[8][8]
conv_image resd     8388608
n	          dd 0 ; define variable n as int 32
m             dd 0 ; define variable m as int 32
k             dd 0 ; define variable k as int 32
read_int_format:    db       "%d",0 ; format to scan
print_int_format:   db       "%d" ,0 ; format to print
read_float_format:  db       "%f" ,0 ; format to scan
print_float_format: db       "%.2f ", 0 ; format to print

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

 print_int: ; for print the result as int  
	sub	rsp, 8
	mov esi, edi ; move the value of edi to esi to print
	mov	rdi,print_int_format ; move int format to print in rdi
	mov	rax, 1
	call printf
	add	rsp, 8
	ret      


main:
    sub rsp, 8

    call read_int ; get the size of image
    mov [n],eax ;copy the input as int to n
    ;we define ebx as (i) and r13d as (j) in a matrix form
    xor ebx,ebx  ; int i = 0

; input matrix of image
INPUT1_LOOP1: ; this loop is for the counter i that show the row of matrix image
    
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,ebx  ; do eax - r14d to make a jump if needed
    jle INPUT1_BREAKLOOP1 ; ;if n <= i break and jump end of loop to do rest of code
    xor r13d,r13d   ; int j = 0
INPUT1_LOOP2: ; this loop is for the counter j that show the column of matrix B
    
    mov eax,[n] ; copy value of n into eax to compare later
    cmp eax,r13d ; do eax - r13d to make a jump if needed
    jle INPUT1_BREAKLOOP2 ;if n<=j break and jump end of loop to do rest of code

    call read_float	; get each element of matrix and copy input in xmm0 ( A[i][j] : A[8*i + j])
	mov	ecx, ebx    ; copy the value of i counter in ecx
	sal	ecx, 11		; i << 3 : mul 2^3=8 so why? we have A[i][j] and its size is A[8][8] so: A[i][j] = A[i*8+j]
	add	ecx, r13d      ; add j to i  
	sal	ecx, 2		; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
	movss	image[ecx], xmm0	; it does A[i][j] = value of xmm0

    inc r13d ; j++
    jmp INPUT1_LOOP2 ; does the loop again
INPUT1_BREAKLOOP2:

    inc ebx ; i++
    jmp INPUT1_LOOP1 ; does the loop again

INPUT1_BREAKLOOP1: 



;input matrix B
xor ebx, ebx  ; int i = 0
call read_int ; to get the size of kernel matrix
mov [m], eax ; move the input as in into m
INPUT2_LOOP1: ; this loop is for the counter i that show the row of matrix B
    mov eax,[m] ; copy value of n into eax to compare later
    cmp eax,ebx ; do eax - r14d to make a jump if needed
    jle INPUT2_BREAKLOOP1 ;if n <= i break and jump end of loop to do rest of code
    xor r13d,r13d   ; int j = 0
INPUT2_LOOP2: ; this loop is for the counter j that show the column of matrix B
    mov eax,[m] ; copy value of n into eax to compare later
    cmp eax,r13d ; do eax - r13d to make a jump if needed
    jle INPUT2_BREAKLOOP2 ;if n<=j break and jump end of loop to do rest of code

    call read_float	; get each element of matrix and copy input in xmm0 ( B[i][j] )
	mov	ecx, ebx    ;;; copy the value of i counter in ecx
	sal	ecx, 3		; i << 3 : mul 2^3=8 so why? we have B[i][j] and its size is B[8][8] so: B[i][j] = B[i*8+j]
	add	ecx, r13d     ; add j to i  
	sal	ecx, 2		; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
	movss	kernel[ecx], xmm0	; it does B[i][j] = value of xmm0

    inc r13d ; j++
    jmp INPUT2_LOOP2 ; does the loop again

INPUT2_BREAKLOOP2:
    inc ebx ; i++
    jmp INPUT2_LOOP1 ; does the loop again

INPUT2_BREAKLOOP1: 


;now we go for compute Convoluton of matrix image by kernel

; the size of final image should be conv_image[n-m+1][n-m+1]
xor r14d, r14d ; int x = 0
mov r14d, [n] ; x = n
sub r14d, [m] ; x = n - m
inc r14d ; x = n - m + 1
mov [k], r14d ; k = x
; so we know the size of final image matrix 
; now we are going to apply convolution

;computing convolution image
xor ebx, ebx    ; int i =0
CONV_LOOP1: 
    mov eax,[k]
    cmp eax,ebx 
    jle CONV_BREAKLOOP1 ;if n<=i break
    xor r13d,r13d   ; int j=0
CONV_LOOP2:
    mov eax,[k]
    cmp eax,r13d
    jle CONV_BREAKLOOP2 ;if n<=j break
    pxor xmm0,xmm0
    ;k = r15d  , p = r14d
    xor r15d, r15d
CONV_LOOP3:
    mov eax,[m]
    cmp eax,r15d  ;
    jle CONV_BREAKLOOP3 ;if m<=k break
    

    xor r14d, r14d
CONV_LOOP4:
    mov eax,[m]
    cmp eax,r14d  ;
    jle CONV_BREAKLOOP4 ;if m<=p break
    

    ; xmm0 += image[i+k][j+p] * kernel[k][p]
    ; xmm1 = image[i+k][j+p]
    ; xmm2 = kernel[k][p]

    mov	ecx,r15d   ; ecx = k    
    add ecx, ebx  ;  k += i
	sal	ecx, 11		; k << 11 because size of array is [2^11][2^11]
	add	ecx, r13d    ; ecx += j
    add ecx, r14d    ; ecx += p    
	sal	ecx, 2		;  becasue our value is 32 bit
	movss	xmm1, image[ecx] ; load value of image base addressing ecx

    mov	ecx,r15d   ; ecx = k    
	sal	ecx, 3		; k << 11 because size of array is [2^3][2^3]
    add ecx, r14d    ; ecx += p    
	sal	ecx, 2		;  becasue our value is 32 bit
	movss	xmm2, kernel[ecx] ; load value of kernel base addressinf ecx

    mulss xmm1,xmm2 ; multiply kernel[k][p] & image[i+k][j+p]
    addss xmm0,xmm1  ; add the result to last sum

    inc r14d 
    jmp CONV_LOOP4
CONV_BREAKLOOP4:
    inc r15d 
    jmp CONV_LOOP3
CONV_BREAKLOOP3:

	mov	ecx, ebx    ; ecx = i
	sal	ecx, 11		; k << 11 because size of array is [2^11][2^11]
	add	ecx, r13d     
	sal	ecx, 2		;  becasue our value is 32 bit
	movss	conv_image[ecx], xmm0	; store dot result of convo and dot product in conv_image[i][j]

    inc r13d ; j++
    jmp CONV_LOOP2
CONV_BREAKLOOP2:
    inc ebx ; i++
    jmp CONV_LOOP1

CONV_BREAKLOOP1: 

;we want to print size of final image
mov edi, [k]
call print_int  
mov edi , 10 ; move the ASCII code of \n into edi
call putchar; print \n


; to print the result of convolution : final image
xor ebx, ebx  ; int i = 0
OUTPUT_LOOP1:
    mov eax,[k] ; copy value of n into eax to compare later
    cmp eax,ebx ; do eax - r14d to make a jump if needed
    jle OUTPUT_BREAKLOOP1 ;if n<=i break
    xor r13d,r13d   ; int j=0
OUTPUT_LOOP2:
    mov eax,[k] ; copy value of n into eax to compare later
    cmp eax,r13d ;  do eax - r13d to make a jump if needed
    jle OUTPUT_BREAKLOOP2 ;if n<=j break

	mov	ecx, ebx    ;
	sal	ecx, 11		; i << 3 : to find the value of C[i*8 + j] to print it
	add	ecx, r13d     
	sal	ecx, 2		; ecx << 2: because our values are dword and 32 bit so we need to skip 4 byte of memory to store each value
	movss	xmm0, conv_image[ecx]	; load and get C[i][j] into xmm0 to print it
    call print_float ; print each element of matrix as float


    inc r13d ;j++
    jmp OUTPUT_LOOP2
OUTPUT_BREAKLOOP2:
    mov edi,10 ; move the ASCII code of \n into edi
    call putchar ; print \n
    inc ebx ;i++
    jmp OUTPUT_LOOP1

OUTPUT_BREAKLOOP1: 
    
    add rsp, 8
    ret
