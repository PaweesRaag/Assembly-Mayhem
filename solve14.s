# Extract the byte in bits 8..15 of the input integer.
# Input: RDI = 64-bit value. Output: RAX = zero-extended selected byte.
.intel_syntax noprefix
.global solve
solve:
    mov rax, rdi                 # Work on a copy of the input.
    shr rax, 8                   # Move original bits 8..15 to low byte.
    and rax, 0xFF                # Discard all bits except that byte.
    ret