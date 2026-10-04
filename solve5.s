# solve5.s — Toggle ASCII letter case using bitwise XOR
#
# Purpose:
#   Walk through a NUL-terminated string and toggle ASCII bit 5 (0x20)
#   for each byte. In ASCII, this bit separates uppercase and lowercase
#   forms of alphabetic characters, so XORing it flips the case.
#
# Input:
#   RDI = address of the first byte of a writable, NUL-terminated string.
#
# Output:
#   The string is modified in place. The routine leaves RDI pointing at
#   the terminating NUL byte. No meaningful value is returned in RAX.
#
# Registers:
#   RDI = current string position.
#   AL  = current character byte.
#
# Memory:
#   [RDI] is read once per iteration and written once after the case bit
#   is toggled.
#
# Control flow:
#   1. Load one byte.
#   2. Stop when the byte is NUL.
#   3. Toggle bit 5 with XOR.
#   4. Store the modified byte.
#   5. Advance and repeat.
#
# Note:
#   This relies on ASCII encoding and is most appropriate for alphabetic
#   ASCII characters. XORing 0x20 on arbitrary punctuation or non-ASCII
#   bytes does not constitute general-purpose case conversion.

.intel_syntax noprefix
.global str_swapcase

str_swapcase:
Loop:
    # Read the current character from the string.
    mov al, BYTE PTR [rdi]

    # A zero byte marks the end of the NUL-terminated string.
    cmp al, 0
    je done

    # Toggle ASCII bit 5. For letters this changes uppercase <-> lowercase.
    xor al, 0x20

    # Write the transformed byte back into the original string.
    mov BYTE PTR [rdi], al

    # Advance to the next character.
    inc rdi

    # Continue processing the string.
    jmp Loop

done:
    # Return once the terminating NUL byte is reached.
    ret
