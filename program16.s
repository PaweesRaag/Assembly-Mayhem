.intel_syntax noprefix
.global _start

_start:
    # Load argc from the initial process stack.
    mov rdi, [rsp]

    # Compare argc with 42 and convert the result to 0 or 1.
    cmp rdi, 42
    setz dil

    # Exit with the comparison result.
    mov eax, 60
    syscall
