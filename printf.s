.intel_syntax noprefix
.global _start

_start:
    mov r12, [rsp+16]
    mov r13, 24

print:
    cmp byte ptr [r12], 0
    je end

    cmp byte ptr [r12], 0x5c
    je check_backslash

    cmp byte ptr [r12], 0x25
    je check_percent

    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_backslash:
    cmp byte ptr [r12+1], 0x6e
    je newline

    cmp byte ptr [r12+1], 0x5c
    je backslash

    cmp byte ptr [r12+1], 0x78
    je hex

    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_percent:
    cmp byte ptr [r12+1], 0x25
    je percent

    cmp byte ptr [r12+1], 0x64
    je decimal

    cmp byte ptr [r12+1], 0x73
    je string

    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

newline:
    mov byte ptr [rsp-1], 0x0a
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2
    jmp print

backslash:
    mov byte ptr [rsp-1], 0x5c
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2
    jmp print

percent:
    mov byte ptr [rsp-1], 0x25
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2
    jmp print

decimal:
    mov rdi, [rsp+r13]
    call atoi

    sub rsp, 128

    mov rsi, rsp
    mov rdi, rax
    call itoa

    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    add rsp, 128
    add r12, 2
    add r13, 8

    jmp print

string:
    mov r11, [rsp+r13]
    mov rsi, r11
    xor rdx, rdx

string_length:
    cmp byte ptr [r11+rdx], 0
    je string_write

    inc rdx
    jmp string_length

string_write:
    mov rax, 1
    mov rdi, 1
    syscall

    add r13, 8
    add r12, 2

    jmp print

hex:
    mov r11b, byte ptr [r12+2]
    call hex_digit

    movzx eax, r11b
    shl eax, 4

    mov r11b, byte ptr [r12+3]
    call hex_digit

    movzx ebx, r11b
    or eax, ebx

    mov byte ptr [rsp-1], al
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 4
    jmp print

hex_digit:
    cmp r11b, 0x30
    jb not_hex

    cmp r11b, 0x39
    jbe digit

    cmp r11b, 0x41
    jb maybe_lower

    cmp r11b, 0x46
    jbe upper

maybe_lower:
    cmp r11b, 0x61
    jb not_hex

    cmp r11b, 0x66
    ja not_hex

    sub r11b, 0x61
    add r11b, 10
    ret

upper:
    sub r11b, 0x41
    add r11b, 10
    ret

digit:
    sub r11b, 0x30
    ret

not_hex:
    jmp end

end:
    mov rax, 60
    xor rdi, rdi
    syscall

atoi:
    xor rax, rax
    xor r8d, r8d

    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    movzx ecx, byte ptr [rdi]

    cmp ecx, 0x30
    jb atoi_done

    cmp ecx, 0x39
    ja atoi_done

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

itoa:
    push rbx

    cmp rdi, 0
    je itoa_zero

    cmp rdi, 0
    jl itoa_negative

    xor rbx, rbx
    xor r9d, r9d
    mov rax, rdi
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    mov r9d, 1

    mov byte ptr [rsi], 0x2D
    inc rsi

    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    xor rdx, rdx
    div rcx

    push rdx
    inc rbx

    cmp rax, 0
    jne itoa_extract

    mov r8, rbx

itoa_write:
    pop rax
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    mov rax, r8

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
