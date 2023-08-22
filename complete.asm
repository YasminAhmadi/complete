%ifndef SYS_EQUAL
%define SYS_EQUAL
    sys_read     equ     0
    sys_write    equ     1
    sys_open     equ     2
    sys_close    equ     3
   
    sys_lseek    equ     8
    sys_create   equ     85
    sys_unlink   equ     87
     

    sys_mmap     equ     9
    sys_mumap    equ     11
    sys_brk      equ     12
   
     
    sys_exit     equ     60
   
    stdin        equ     0
    stdout       equ     1
    stderr       equ     3

 
 
    PROT_READ     equ   0x1
    PROT_WRITE    equ   0x2
    MAP_PRIVATE   equ   0x2
    MAP_ANONYMOUS equ   0x20
   
    ;access mode
    O_RDONLY    equ     0q000000
    O_WRONLY    equ     0q000001
    O_RDWR      equ     0q000002
    O_CREAT     equ     0q000100
    O_APPEND    equ     0q002000

   
; create permission mode
    sys_IRUSR     equ     0q400      ; user read permission
    sys_IWUSR     equ     0q200      ; user write permission

    NL            equ   0xA
    Space         equ   0x20

%endif
;----------------------------------------------------
newLine:
   push   rax
   mov    rax, NL
   call   putc
   pop    rax
   ret
;---------------------------------------------------------
putc:

   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

   push   ax
   mov    rsi, rsp    ; points to our char
   mov    rdx, 1      ; how many characters to print
   mov    rax, sys_write
   mov    rdi, stdout
   syscall
   pop    ax

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx
   ret
;---------------------------------------------------------
writeNum:
   push   rax
   push   rbx
   push   rcx
   push   rdx

   sub    rdx, rdx
   mov    rbx, 10
   sub    rcx, rcx
   cmp    rax, 0
   jge    wAgain
   push   rax
   mov    al, '-'
   call   putc
   pop    rax
   neg    rax  

wAgain:
   cmp    rax, 9
   jle    cEnd
   div    rbx
   push   rdx
   inc    rcx
   sub    rdx, rdx
   jmp    wAgain

cEnd:
   add    al, 0x30
   call   putc
   dec    rcx
   jl     wEnd
   pop    rax
   jmp    cEnd
wEnd:
   pop    rdx
   pop    rcx
   pop    rbx
   pop    rax
   ret

;---------------------------------------------------------
getc:
   push   rcx
   push   rdx
   push   rsi
   push   rdi
   push   r11

 
   sub    rsp, 1
   mov    rsi, rsp
   mov    rdx, 1
   mov    rax, sys_read
   mov    rdi, stdin
   syscall
   mov    al, [rsi]
   add    rsp, 1

   pop    r11
   pop    rdi
   pop    rsi
   pop    rdx
   pop    rcx

   ret
;---------------------------------------------------------

readNum:
   push   rcx
   push   rbx
   push   rdx

   mov    bl,0
   mov    rdx, 0
rAgain:
   xor    rax, rax
   call   getc
   cmp    al, '-'
   jne    sAgain
   mov    bl,1  
   jmp    rAgain
sAgain:
   cmp    al, NL
   je     rEnd
   cmp    al, ' ' ;Space
   je     rEnd
   sub    rax, 0x30
   imul   rdx, 10
   add    rdx,  rax
   xor    rax, rax
   call   getc
   jmp    sAgain
rEnd:
   mov    rax, rdx
   cmp    bl, 0
   je     sEnd
   neg    rax
sEnd:  
   pop    rdx
   pop    rbx
   pop    rcx
   ret

;-------------------------------------------
printString:
    push    rax
    push    rcx
    push    rsi
    push    rdx
    push    rdi

    mov     rdi, rsi
    call    GetStrlen
    mov     rax, sys_write  
    mov     rdi, stdout
    syscall
   
    pop     rdi
    pop     rdx
    pop     rsi
    pop     rcx
    pop     rax
    ret
;-------------------------------------------
; rsi : zero terminated string start
GetStrlen:
    push    rbx
    push    rcx
    push    rax  

    xor     rcx, rcx
    not     rcx
    xor     rax, rax
    cld
    repne   scasb
    not     rcx
    lea     rdx, [rcx -1]  ; length in rdx

    pop     rax
    pop     rcx
    pop     rbx
    ret
;-------------------------------------------


section .data
        Perfect db 'Perfect',0
        space db ' ',0
        Nope db 'Nope'
        newline db 0ah
section .bss
        num: resb 4
section .text
        global _start

_start:
        call readNum
_check_one:
        cmp rax, 1
        jne _check_others
        mov rsi, Perfect
        call printString
        call newLine
        call writeNum
        jmp Exit        
_check_others:
        mov [num], rax
        ; storing the number in r9
        mov r9,[num]
        ; storing the number in r10
        mov r10,[num]
        ;with the help of r11 which is first set to 0 then 1
        ;we check if the number is one or zero which are exceptions
        ;jumping straight to printing 'Nope'
        xor r11, r11
        cmp r9, r11
        ; if the number is 0
        je ex
        xor r11, r11
        inc r11
        cmp r9, r11
        ; if the number is 1
        je ex
        xor r8, r8
        ; r8 <-- 1
        inc r8
        ; r14 to store the sum
        ; r14 <-- 0
        xor r14, r14
        jmp loop
        jmp Exit

loop:
        ;r9 is the number and r8 starts from 1 increasing up to r9
        mov rax,r9
        xor rdx, rdx
        ;we divide r9 by r8 to see whether r8 is a divisor of the number
        div r8
        xor r11, r11
        cmp rdx, r11
        ; if r8 is a divisor of the number go to 'firstcheck'
        je firstcheck
        inc r8
        jmp loop
       
firstcheck:
        ; r8 is a divisor so we add it to sum (r14)
        mov rax, r8
        add r14, rax
        ; if the divisor we just found is the same as our number, we are done.
        cmp r8, r9
        je check
        inc r8
        jmp loop
check:
        ;we are done with finding the divisors now we determine
        ;if the number is perfect or not
        add r9, r9
        cmp r9 ,r14
        je printPerfect
        ; if not equal --> not complete
        jmp printNope
       
printPerfect:  
        mov rsi, Perfect
        call printString
        mov rsi, newline
        call printString
        ; now we need to print the divisors
        jmp prep
       
printNope:  
        mov rsi, Nope
        call printString
        jmp prep
prep:
        ;preparation for print numbers in the next line
        ;moving the number to r9
        mov r9, r10
        ;if the number is 0 or 1 we directly jump to printing 'Nope'
        xor r11, r11
        cmp r9, r11
        je ex
        xor r11, r11
        inc r11
        cmp r9, r11
        je ex
        xor r8, r8
        inc r8
        ;r14 to store the sum
        xor r14, r14
        ; if the number is not 0 or 1 now it's time to print the divisors
        jmp printNums
printNums:
        ;works just like 'loop'
        mov rax,r9
        xor rdx, rdx
        div r8
        xor r11, r11
        cmp rdx, r11
        je checkonee
        inc r8
        jmp printNums
       
checkonee:
        ;works just like 'checkone'
        ; checking if all the divisors are already printed
        cmp r8, r9
        je Exit
        ; checking if the divisor is 1
        xor r15, r15
        inc r15
        cmp r15, r8
        je one
        jmp notone
one:
        ;if the divisor is one we come here since it's different from
        ;other divisors in the sense that we do not put an space before
        mov rax, r8
        call writeNum
        mov rax, r8
        add r14, rax
        inc r8
        jmp printNums
notone:
        ;if the divisor is not 1 then we have to put space before it
        mov rsi, space
        call printString
        mov rax, r8
        call writeNum
        mov rax, r8
        add r14, rax
        inc r8
        jmp printNums
ex:  
        ; if the number is 0 or 1 we just print Nope
        ; as they have no smaller divisor
        mov rsi, Nope
        call printString
        jmp Exit
Exit:
        call newLine
        mov rax, 1
        mov rbx, 0
        int 0x80
