.intel_syntax noprefix
.global itoa
# Convert signed integer to decimal ASCII. RSI points to writable output.
# RAX returns the character count; no NUL terminator is written.
# Note: this supplied learning implementation uses R9 to identify negatives,
# but does not initialize R9 here; treat it as an exercise needing review.
itoa:
    cmp rdi, 0
    je zero
    jl Negative_number
    push rbx
    mov rax, rdi
    xor rbx, rbx
    mov rcx, 10
    jmp extract_loop
Negative_number:
    push rbx
    mov BYTE PTR [rsi], 0x2D  # Write '-' sign.
    inc rsi
    neg rdi                   # Convert magnitude (INT64_MIN needs special care).
    mov rax, rdi
    xor rbx, rbx
    mov rcx, 10
extract_loop:
    xor rdx, rdx
    div rcx
    push rdx                  # Save next least-significant digit.
    inc rbx
    cmp rax, 0
    jne extract_loop
    mov r8, rbx
write_loop:
    pop rax
    add al, 0x30
    mov BYTE PTR [rsi], al
    inc rsi
    dec rbx
    jnz write_loop
    mov rax, r8
    cmp r9, 1
    je negative_length
    pop rbx
    ret
zero:
    mov BYTE PTR [rsi], 0x30
    mov rax, 1
    ret
negative_length:
    add rax, 1
    pop rbx
    ret