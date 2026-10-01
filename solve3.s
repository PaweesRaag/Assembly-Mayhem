# solve3.s — Return the first argument unchanged
#
# Purpose:
#   Minimal example of the System V AMD64 calling convention. The first
#   integer/pointer argument arrives in RDI, while a function return value
#   is expected in RAX.
#
# Input:
#   RDI = value supplied by the caller.
#
# Output:
#   RAX = the same value.
#
# Memory:
#   No memory is accessed. The routine only transfers a value between
#   registers.
#
# Control flow:
#   There is no branch or loop. The function copies RDI to RAX and returns.

.intel_syntax noprefix
.global solve

solve:
    # Copy the caller's first argument into the return-value register.
    mov rax, rdi

    # Return to the caller. RAX now contains the result.
    ret
