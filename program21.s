.intel_syntax noprefix
.global _start

_start:
    # Write up to 128 bytes from argv[2] to stdout.
    mov rax, 1
    mov rdi, 1
    mov rsi, [rsp+24]
    mov rdx, 128
    syscall

    # Exit successfully.
    mov rax, 60
    xor rdi, rdi
    syscall
