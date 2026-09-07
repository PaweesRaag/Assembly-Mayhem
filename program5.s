.intel_syntax noprefix
.global _start

_start:
    # Read the pointer stored at RDI + 8.
    # This accesses the next 8-byte value after the address in RDI.
    mov rdi, [rdi+8]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
