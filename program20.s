.intel_syntax noprefix
.global _start

_start:
    # Start the string-length counter at zero.
    mov rsi, 0

    # Check argc. With no user-supplied argument, exit immediately.
    cmp QWORD PTR [rsp], 1
    je EXIT

    # Load a pointer to argv[1].
    mov rdi, [rsp+16]

LOOP:
    # Stop when the NUL terminator is reached.
    cmp BYTE PTR [rdi+rsi], 0
    je EXIT

    # Advance to the next character.
    inc rsi
    jmp LOOP

EXIT:
    # Return the calculated string length as the exit status.
    mov rdi, rsi
    mov rax, 60
    syscall
