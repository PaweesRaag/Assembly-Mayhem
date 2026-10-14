.intel_syntax noprefix
.global LOBYTE
# Return the low eight bits of the input, zero-extended in RAX.
LOBYTE:
    mov rax, rdi
    and rax, 0xFF
    ret