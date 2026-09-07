.intel_syntax noprefix
.global _start

_start:
    # Linux x86-64: syscall 60 is exit(status)
    mov rax, 60

    # Load the 8-byte value stored at memory address 0x123400.
    # RDI becomes the exit status passed to exit().
    mov rdi, [0x123400]

    # Terminate the process using the value loaded from memory.
    syscall
