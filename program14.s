.intel_syntax noprefix
.global _start

_start:
    # Open the file whose pathname is argv[1].
    mov rdi, [rsp+16]
    mov rsi, 0
    mov rax, 2
    syscall

    # Use the returned file descriptor for read().
    mov rdi, rax
    mov rsi, rsp
    mov rdx, 128
    mov rax, 0
    syscall

    # Write exactly the number of bytes read to stdout.
    mov rdi, 1
    mov rsi, rsp
    mov rdx, rax
    mov rax, 1
    syscall

    # Exit with status 42.
    mov rdi, 42
    mov rax, 60
    syscall
