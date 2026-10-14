# Toggle ASCII case bit for each byte in a NUL-terminated string.
# Input: RDI = writable string. Output: modified string in place.
# XOR with 0x20 flips bit 5; suitable for ASCII letters, not general Unicode.
.intel_syntax noprefix
.global str_swapcase
str_swapcase:
Loop:
    mov al, BYTE PTR [rdi]       # Load current byte.
    cmp al, 0                    # Stop at the string terminator.
    je done
    xor al, 0x20                 # Toggle ASCII case bit.
    mov BYTE PTR [rdi], al       # Write modified character.
    inc rdi                      # Move to next byte.
    jmp Loop
done:
    ret