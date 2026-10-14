# Convert an ASCII digit character to its numeric value.
# Input: RDI points to a one-character NUL-terminated string.
# Output: RAX = byte at [RDI] minus ASCII '0' (0x30).
# This assumes the input byte is a decimal digit; it does not validate it.
.intel_syntax noprefix
.global atoi_digit
atoi_digit:
    # Zero-extend the character byte so upper bits of RAX are cleared.
    movzx rax, BYTE PTR [rdi]
    # ASCII digits '0'..'9' have codes 0x30..0x39.
    sub rax, 0x30
    ret