.intel_syntax noprefix

.global _start


_start:
    ; argc
    mov r13, [rsp]

    ; argv[1]
    lea r12, [rsp + 16]

    ; total = 0
    xor r14, r14


sum_loop:
    ; argc <= 1 means no more numbers
    cmp r13, 1
    je sum_done

    ; atoi(argv[i])
    mov rdi, [r12]
    call atoi

    ; total += atoi result
    add r14, rax

    ; next argv entry
    add r12, 8
    dec r13

    jmp sum_loop


sum_done:
    ; scratch buffer
    sub rsp, 32

    ; itoa(total, rsp)
    mov rdi, r14
    mov rsi, rsp
    call itoa

    ; write(1, rsp, returned_length)
    mov rdx, rax
    mov rax, 1
    mov rdi, 1
    mov rsi, rsp
    syscall

    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall



; =========================================================
; atoi
; RDI = string
; RAX = signed integer
; =========================================================

atoi:
    xor rax, rax
    xor r8d, r8d

    ; Is first character '-'?
    cmp byte ptr [rdi], 0x2d
    jne atoi_loop

    mov r8d, 1
    inc rdi


atoi_loop:
    movzx ecx, byte ptr [rdi]

    ; Not a digit?
    cmp ecx, 0x30
    jb atoi_done

    cmp ecx, 0x39
    ja atoi_done

    ; total = total * 10 + digit
    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop


atoi_done:
    cmp r8d, 1
    jne atoi_return

    neg rax

atoi_return:
    ret



; =========================================================
; itoa
; RDI = signed integer
; RSI = buffer
; RAX = length
; =========================================================

itoa:
    push rbx

    ; zero?
    cmp rdi, 0
    je itoa_zero

    ; negative?
    jl itoa_negative

    ; positive
    xor rbx, rbx
    xor r9d, r9d          ; sign = 0
    mov rax, rdi
    mov rcx, 10

    jmp itoa_extract


itoa_negative:
    ; sign = 1
    mov r9d, 1

    ; write '-'
    mov byte ptr [rsi], 0x2d
    inc rsi

    ; magnitude
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10


itoa_extract:
    xor rdx, rdx
    div rcx

    ; remainder = next digit
    push rdx
    inc rbx

    ; quotient == 0?
    cmp rax, 0
    jne itoa_extract

    ; Save digit count
    mov r8, rbx


itoa_write:
    pop rax

    ; number → ASCII
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    ; return digit count
    mov rax, r8

    ; Add '-' to returned length if needed
    cmp r9d, 1
    jne itoa_finish

    add rax, 1


itoa_finish:
    pop rbx
    ret


itoa_zero:
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
