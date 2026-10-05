# solve6.s — Multiply an unsigned integer by 16 using a left shift
#
# Purpose:
#   Demonstrates how a bit shift can implement multiplication by a power
#   of two. Shifting left by four positions multiplies the value by 2^4 = 16.
#
# Input:
#   RDI = unsigned integer supplied by the caller.
#
# Output:
#   RAX = RDI * 16, subject to normal 64-bit integer wraparound.
#
# Registers:
#   RDI = input value.
#   RAX = working register and return-value register.
#
# Memory:
#   No memory is accessed. The entire operation is register-only.
#
# Instruction flow:
#   1. Copy the input from RDI into RAX.
#   2. Shift RAX left by four bits.
#   3. Return with the result in RAX.
#
# Bit-level intuition:
#   A left shift by one bit multiplies an unsigned value by 2.
#   Therefore a shift by four bits multiplies it by 2^4 = 16.

.intel_syntax noprefix
.global solve

solve:
    # Move the first argument into the register used for the return value.
    mov rax, rdi

    # Shift every bit four places to the left.
    # This is equivalent to multiplying the value by 16.
    shl rax, 4

    # Return the computed value in RAX.
    ret
