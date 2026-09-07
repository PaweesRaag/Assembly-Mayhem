.intel_syntax noprefix
.global _start

_start:
    # Remove argc from the initial stack by popping it into RDI.
    # RDI is then passed as the exit status.
    pop rdi

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
