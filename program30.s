; Program 30 — Calculator with binary and unary operators
; Binary form:  program LEFT OP RIGHT
; Unary form:   program OP VALUE
; Binary operators: + - * ^ | &
; Unary operators:  ~ -

.intel_syntax noprefix
.global _start

_start:
    ; argc == 3 means the unary form: program OP VALUE.
    mov rdi, [rsp]
    cmp rdi, 3
    je unary

binary:
    ; Parse left operand: argv[1].
    mov rdi, [rsp+16]
    call atoi
    mov rbx, rax

    ; Parse right operand: argv[3].
    mov rdi, [rsp+32]
    call atoi

    ; Load binary operator: argv[2].
    mov r11, [rsp+24]

    cmp byte ptr [r11], 0x2B   ; '+'
    je add
    cmp byte ptr [r11], 0x2D   ; '-'
    je sub
    cmp byte ptr [r11], 0x2A   ; '*'
    je mul
    cmp byte ptr [r11], 0x5E   ; '^'
    je xor_operation
    cmp byte ptr [r11], 0x7C   ; '|'
    je or_operation
    cmp byte ptr [r11], 0x26   ; '&'
    je and_operation

unary:
    ; Unary form: operator is argv[1], operand is argv[2].
    mov r11, [rsp+16]
    mov rdi, [rsp+24]
    call atoi

    cmp byte ptr [r11], 0x7E   ; '~'
    je not_operation
    cmp byte ptr [r11], 0x2D   ; '-'
    je nega

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
    add rax, rbx
    jmp function

sub:
    sub rbx, rax
    mov rax, rbx
    jmp function

mul:
    imul rax, rbx
    jmp function

xor_operation:
    xor rax, rbx
    jmp function

or_operation:
    or rax, rbx
    jmp function

and_operation:
    and rax, rbx
    jmp function

not_operation:
    not rax                 ; Bitwise NOT for unary '~'.
    jmp function

nega:
    neg rax                 ; Arithmetic negation for unary '-'.
    jmp function
