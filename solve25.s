.intel_syntax noprefix
.global itoa_digit
# Input: RDI = integer digit 0..9. Output: RAX = ASCII code for that digit.
itoa_digit:
    mov rax, rdi
    add rax, 0x30              # Map numeric 0..9 to ASCII '0'..'9'.
    ret