.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to argv[1], which contains the decimal string.
    mov rdi, [rsp+16]

atoi:
    # Accumulate the parsed integer in RBX.
    xor rbx, rbx

Loop:
    # Load the current ASCII character and zero-extend it.
    movzx rax, byte ptr [rdi]

    # Stop at the NUL terminator.
    cmp rax, 0x0
    je end

    # Convert the ASCII digit to its numeric value and
    # append it to the accumulated decimal number.
    imul rbx, 10
    sub rax, 0x30
    add rbx, rax

    # Advance to the next character.
    inc rdi
    jmp Loop

end:
    # Exit with the parsed integer as the process status.
    mov rdi, rbx
    mov rax, 60
    syscall
