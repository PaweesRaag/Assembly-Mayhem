.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to argv[1], which contains the string to parse.
    mov rdi, [rsp+16]

atoi:
    # Accumulate the parsed decimal value in RBX.
    xor rbx, rbx

Loop:
    # Load the current ASCII character and zero-extend it.
    movzx rax, byte ptr [rdi]

    # Stop when the NUL terminator is reached.
    cmp rax, 0x0
    je end

    # Shift the accumulated decimal value left by one digit:
    # value = value * 10 + current_digit.
    imul rbx, 10
    sub rax, 0x30
    add rbx, rax

    # Advance to the next character.
    inc rdi
    jmp Loop

end:
    # Return the parsed value through the process exit status.
    mov rdi, rbx
    mov rax, 60
    syscall
