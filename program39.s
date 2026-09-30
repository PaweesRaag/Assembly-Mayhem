# program39.s — Return the first argument unchanged
# Demonstrates the System V AMD64 convention: RDI is the first argument and RAX is the return register.
# Input: RDI = value supplied by the caller.
# Output: RAX = the same value.
# No explicit memory access is performed; the routine operates entirely on registers.
.intel_syntax noprefix
.global solve
solve:
    # Copy the first argument into the return-value register.
    mov rax, rdi
    # Return to the caller with RAX holding the result.
    ret
