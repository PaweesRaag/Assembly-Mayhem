.intel_syntax noprefix
.global atoi
.global atoi_digit
# Parse a NUL-terminated non-negative decimal string at RDI.
atoi:
    push rbx
    xor rbx, rbx               # Decimal accumulator starts at zero.
Loop:
    cmp BYTE PTR [rdi], 0      # Stop at NUL.
    je end
    imul rbx, 10               # Shift existing digits one decimal place.
    call atoi_digit            # Convert current character.
    add rbx, rax
    inc rdi
    jmp Loop
end:
    mov rax, rbx               # Return accumulated value.
    pop rbx
    ret
atoi_digit:
    movzx rax, BYTE PTR [rdi]
    sub rax, 0x30
    ret