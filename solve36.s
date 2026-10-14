.intel_syntax noprefix
.global chr_lower
# Set ASCII bit 5 on the input character; for uppercase ASCII letters this
# produces the lowercase equivalent. Not a general Unicode case conversion.
chr_lower:
    mov rax, rdi
    or rax, 0b100000
    ret