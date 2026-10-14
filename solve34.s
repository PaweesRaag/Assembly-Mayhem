.intel_syntax noprefix
.global solve
# Return 1 for even input and 0 for odd input, using the least-significant bit.
solve:
    mov rax, rdi
    and rax, 1                 # Odd values have low bit 1.
    xor rax, 1                 # Invert: even -> 1, odd -> 0.
    ret