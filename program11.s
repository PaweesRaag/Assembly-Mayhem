.intel_syntax noprefix
.global _start

_start:
    # write(fd=1, buf=argv[1], count=64)
    # Attempt to print up to 64 bytes starting at argv[1].
    mov rdi, 1
    mov rsi, [rsp+16]
    mov rdx, 64
    mov rax, 1
    syscall

    # Exit with status 42.
    mov rdi, 42
    mov rax, 60
    syscall
