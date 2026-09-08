.intel_syntax noprefix
.global _start

_start:
    # Read up to 128 bytes from stdin into the stack buffer.
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 128
    mov rax, 0
    syscall

    # Use the number of bytes read as the write length.
    mov rdx, rax

    # Echo exactly the bytes that were read.
    mov rdi, 1
    mov rsi, rsp
    mov rax, 1
    syscall

    # Exit with status 42.
    mov rdi, 42
    mov rax, 60
    syscall
