.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to argv[1].
    mov rdi, [rsp+16]

    # Check whether the first character is 'p'.
    cmp BYTE PTR [rdi], 'p'
    setz dil

    # Exit with 1 if it does not match, or 0 if it does.
    mov rax, 60
    syscall
