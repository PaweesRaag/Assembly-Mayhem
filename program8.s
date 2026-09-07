.intel_syntax noprefix
.global _start

_start:
    # At process entry, [rsp+16] is argv[1].
    # Load argv[1], then dereference it once more.
    mov rdi, [rsp+16]
    mov rdi, [rdi]

    # syscall 60 = exit(status)
    mov rax, 60
    syscall
