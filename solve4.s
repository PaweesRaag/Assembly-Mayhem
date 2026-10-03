# solve4.s — Convert a NUL-terminated ASCII string to uppercase
#
# Purpose:
#   Walk through a string one byte at a time and clear ASCII bit 5 for
#   each character. For ordinary lowercase ASCII letters, this converts
#   'a'..'z' into 'A'..'Z'.
#
# Input:
#   RDI = address of the first byte of a writable, NUL-terminated string.
#
# Output:
#   The string is modified in place. RDI is left pointing one byte past
#   the terminating NUL. No meaningful value is returned in RAX.
#
# Registers:
#   RDI = current character address / string cursor.
#   AL  = current character byte loaded from memory.
#
# Memory:
#   One byte is read from [RDI] and, when processing continues, the
#   transformed byte is written back to the same address.
#
# Control flow:
#   The loop stops when the loaded byte is zero, which is the C-string
#   NUL terminator. Otherwise the character is transformed, RDI advances,
#   and execution jumps back to the start of the loop.
#
# Note:
#   ASCII bit 0x20 distinguishes lowercase from uppercase letters.
#   Clearing that bit converts lowercase letters to uppercase. This
#   simple operation assumes ASCII-style character encoding and is not
#   a complete Unicode uppercase conversion.

.intel_syntax noprefix
.global str_upper

str_upper:
loop:
    # Load the current character from the string into the low byte of RAX.
    mov al, BYTE PTR [rdi]

    # A zero byte marks the end of a NUL-terminated string.
    cmp al, 0
    je done

    # Clear ASCII bit 5 (0x20). For lowercase letters, this changes
    # 'a'..'z' into their corresponding uppercase characters.
    and al, 0xDF

    # Store the converted byte back into the original string.
    mov BYTE PTR [rdi], al

    # Advance to the next character.
    inc rdi

    # Repeat until the terminating NUL byte is encountered.
    jmp loop

done:
    # Return to the caller. The string has been modified in place.
    ret
