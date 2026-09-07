.intel_syntax noprefix
.global _start

_start:
    # Dereference the address currently held in RAX.
    # The loaded value becomes the exit status.
    mov rdi, [rax]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
