# Convert a NUL-terminated ASCII string to uppercase in place.
# Input: RDI = writable string address. Output: string modified in memory.
# AL temporarily holds each byte; RDI advances through the string.
# Clearing bit 5 converts lowercase ASCII letters to uppercase; this is
# not Unicode-aware and can also change non-letter bytes.
.intel_syntax noprefix
.global str_upper
str_upper:
loop:
    mov al, BYTE PTR [rdi]       # Read current character.
    cmp al, 0                    # NUL terminator?
    je done
    and al, 0xDF                 # Clear ASCII lowercase bit.
    mov BYTE PTR [rdi], al       # Store converted byte.
    inc rdi                      # Advance to next character.
    jmp loop
done:
    ret