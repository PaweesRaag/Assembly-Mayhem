.intel_syntax noprefix
.global _start

_start:
    # First dereference the address stored in RAX.
    mov rdi, [rax]

    # Dereference that resulting pointer again.
    mov rdi, [rdi]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
