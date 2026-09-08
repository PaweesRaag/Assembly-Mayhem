.intel_syntax noprefix
.global _start

_start:
    # Load a pointer to argv[1].
    mov rax, [rsp+16]

    # Check that the first three characters are "pwn".
    cmp BYTE PTR [rax], 'p'
    jne fail
    cmp BYTE PTR [rax+1], 'w'
    jne fail
    cmp BYTE PTR [rax+2], 'n'
    jne fail

    # All characters matched: exit successfully.
    mov rdi, 0
    mov rax, 60
    syscall

fail:
    # At least one character did not match: exit with status 1.
    mov rdi, 1
    mov rax, 60
    syscall
