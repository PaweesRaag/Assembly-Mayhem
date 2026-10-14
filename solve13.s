# Multiply an integer by 16 using a four-bit left shift.
# Input: RDI = value. Output: RAX = RDI * 16 modulo 2^64.
# No memory accesses or branches are needed.
.intel_syntax noprefix
.global solve
solve:
    mov rax, rdi                 # Copy input into return register.
    shl rax, 4                   # Shift left four bits: multiply by 2^4.
    ret