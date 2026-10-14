# Write 64 bytes from a stack-relative buffer to standard output.
# Assumption: [RSP+0x40] points to 64 readable bytes prepared by the caller.
# Linux x86-64 syscall ABI: RAX=number, RDI=fd, RSI=buffer, RDX=count.
.intel_syntax noprefix
.global solve
solve:
    lea rsi, [rsp+0x40]           # Compute buffer address; LEA doesn't load it.
    mov rdi, 1                    # File descriptor 1 = stdout.
    mov rdx, 64                   # Request 64 bytes.
    mov rax, 1                    # Linux x86-64 SYS_write.
    syscall                       # Kernel attempts write(1, buffer, 64).
    ret                           # RAX retains syscall result.