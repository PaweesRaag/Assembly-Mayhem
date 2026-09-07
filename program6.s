.intel_syntax noprefix
.global _start

_start:
    # Load a value from the absolute address 0x8A708.
    mov rdi, [0x8A708]

    # Dereference the value just loaded and use the result
    # as the exit status.
    mov rdi, [rdi]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
