.intel_syntax noprefix
.global _start

_start:
    # read(fd=0, buf=rsp, count=128)
    # Read up to 128 bytes from stdin into the stack buffer.
    mov rdi, 0
    mov rsi, rsp
    mov rdx, 128
    mov rax, 0
    syscall

    # write(fd=1, buf=rsp, count=128)
    # Echo the 128-byte buffer to stdout.
    mov rdi, 1
    mov rsi, rsp
    mov rdx, 128
    mov rax, 1
    syscall

    # Exit with status 42.
    mov rdi, 42
    mov rax, 60
    syscall
