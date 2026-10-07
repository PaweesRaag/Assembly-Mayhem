# solve7.s — Extract one byte from an integer using shifts and a mask
#
# Purpose:
#   Demonstrates how shifting and masking can isolate a particular byte
#   from a larger 64-bit integer.
#
# Input:
#   RDI = source 64-bit integer.
#
# Output:
#   RAX = the byte originally located in bits 8..15 of RDI, returned as
#         a zero-extended 64-bit value.
#
# Registers:
#   RDI = input value; remains unchanged by this routine.
#   RAX = working register and return-value register.
#
# Memory:
#   No memory is accessed. The operation is entirely register-based.
#
# How it works:
#   1. Copy RDI into RAX.
#   2. Shift RAX right by 8 bits so the target byte moves into bits 0..7.
#   3. Mask with 0xFF so every other bit is discarded.
#
# Example:
#   RDI = 0x1122334455667788
#   After SHR 8:
#          0x0011223344556677
#   After AND 0xFF:
#          0x0000000000000077
#
# Control flow:
#   Straight-line execution with no branches or loops.

.intel_syntax noprefix
.global solve

solve:
    # Copy the input into the return-value register.
    mov rax, rdi

    # Move the second byte of the original value into the low byte.
    shr rax, 8

    # Keep only the low 8 bits, discarding everything else.
    and rax, 0xFF

    # Return the extracted byte in RAX.
    ret
