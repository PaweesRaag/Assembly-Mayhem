.intel_syntax noprefix
.global _start

_start:
    # write(fd=1, buf=argv[1], count=1)
    # Print the first byte of argv[1] to stdout.
    mov rdi, 1
    mov rsi, [rsp+16]
    mov rdx, 1
    mov rax, 1
    syscall
