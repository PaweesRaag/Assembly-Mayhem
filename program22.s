.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to the numeric argument in argv[1].
    mov rdi, [rsp+16]

atoi:
    # Accumulate the parsed integer in RBX.
    xor rbx, rbx

Loop:
    # Load the current ASCII character.
    movzx rax, byte ptr [rdi]

    # Stop at the NUL terminator.
    cmp rax, 0x0
    je end

    # Multiply the current value by 10 and add the next digit.
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
