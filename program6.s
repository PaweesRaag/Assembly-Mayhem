.intel_syntax noprefix
.global _start

_start:
    # Load a value from the absolute address 567800.
    mov rdi, [567800]

    # Dereference the value just loaded and use the result
    # as the exit status.
    mov rdi, [rdi]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
