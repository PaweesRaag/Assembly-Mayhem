.intel_syntax noprefix
.global atoi_digit
# Input: RDI points to an ASCII digit. Output: RAX = character code minus '0'.
# No validation is performed; callers must supply a decimal digit.
atoi_digit:
    movzx rax, BYTE PTR [rdi]  # Load byte and clear upper bits.
    sub rax, 0x30              # Convert ASCII digit to its numeric value.
    ret