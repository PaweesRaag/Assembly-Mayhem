.intel_syntax noprefix
.global itoa
# Convert a non-negative integer to decimal ASCII using repeated division.
# Input: RDI=value, RSI=output buffer. Output RAX=digit count; no NUL added.
# Each remainder is pushed, then popped to emit digits most-significant first.
itoa:
    cmp rdi, 0
    je zero
    push rbx
    mov rax, rdi
    xor rbx, rbx               # RBX counts digits extracted.
    mov rcx, 10
extract_loop:
    xor rdx, rdx               # Clear high dividend before DIV.
    div rcx                    # Quotient in RAX, remainder in RDX.
    push rdx
    inc rbx
    cmp rax, 0
    jne extract_loop
    mov r8, rbx                # Preserve output length.
write_loop:
    pop rax
    add al, 0x30               # Convert remainder to ASCII digit.
    mov BYTE PTR [rsi], al
    inc rsi
    dec rbx
    jnz write_loop
    mov rax, r8
    pop rbx
    ret
zero:
    mov BYTE PTR [rsi], 0x30
    mov rax, 1
    ret