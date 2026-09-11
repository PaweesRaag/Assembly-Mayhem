; Program 28 — Binary calculator: +, -, and *
; Parse two signed decimal operands and dispatch based on argv[2].
; Supports addition, subtraction, and multiplication.

.intel_syntax noprefix
.global _start

_start:
    ; Parse left operand: argv[1].
    mov rdi, [rsp+16]
    call atoi
    mov rbx, rax

    ; Parse right operand: argv[3].
    mov rdi, [rsp+32]
    call atoi

    ; Load operator string pointer: argv[2].
    mov r11, [rsp+24]

    ; Dispatch on the first operator character.
    cmp byte ptr [r11], 0x2B   ; '+'
    je add
    cmp byte ptr [r11], 0x2D   ; '-'
    je sub
    cmp byte ptr [r11], 0x2A   ; '*'
    je mul
    jmp end

; Shared result-output path.
function:
    sub rsp, 128              ; Reserve output buffer.
    mov rsi, rsp
    mov rdi, rax
    call itoa

    ; write(stdout, buffer, length)
    mov rdx, rax
    mov rdi, 1
    mov rsi, rsp
    mov rax, 1
    syscall

    xor rdi, rdi              ; exit status = 0

end:
    mov rax, 60
    syscall

; ---------------------------------------------------------------------------
; atoi — signed decimal string to integer
; ---------------------------------------------------------------------------
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

; ---------------------------------------------------------------------------
; itoa — signed integer to decimal ASCII
; ---------------------------------------------------------------------------
itoa:
    push rbx

    cmp rdi, 0
    je itoa_zero
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

add:
    add rax, rbx              ; left + right
    jmp function

sub:
    sub rbx, rax              ; left - right
    mov rax, rbx
    jmp function

mul:
    imul rax, rbx              ; left * right
    jmp function
