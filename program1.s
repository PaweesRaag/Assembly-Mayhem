.intel_syntax noprefix
.global _start

_start:
    # At program entry on Linux x86-64, the initial stack contains:
    #   [rsp]     = argc
    #   [rsp+8]   = argv[0]
    #   [rsp+16]  = argv[1]
    #   ...
    #
    # Copy the current stack pointer into RDI. The exit syscall
    # interprets RDI as the process exit status.
    mov rdi, rsp

    # syscall 60 = exit
    mov rax, 60
    syscall
