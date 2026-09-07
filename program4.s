.intel_syntax noprefix
.global _start

_start:
    # Dereference the pointer in RDI and use the loaded value
    # as the exit status.
    mov rdi, [rdi]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
