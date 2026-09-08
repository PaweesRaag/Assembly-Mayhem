.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to argv[1].
    mov rdi, [rsp+16]

    # Check whether the first character is 'p'.
    cmp BYTE PTR [rdi], 'p'
    jne fail

    # Matching character: exit successfully.
    mov rdi, 0
    mov rax, 60
    syscall

fail:
    # Character did not match: exit with status 1.
    mov rdi, 1
    mov rax, 60
    syscall
