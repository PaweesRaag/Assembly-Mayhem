.intel_syntax noprefix
.global itoa
.global itoa_digit
# Convert an integer 0..99 into exactly two ASCII characters.
# Input: RDI=value, RSI=buffer of at least 2 bytes. Output RAX=2.
# No NUL terminator is appended; caller must provide a writable buffer.
itoa:
    xor rdx, rdx               # DIV uses RDX:RAX as dividend.
    mov rax, rdi
    mov rcx, 10
    div rcx                    # Quotient=tens in RAX; remainder=ones in RDX.
    add rax, 0x30
    add rdx, 0x30
    mov BYTE PTR [rsi], al
    mov BYTE PTR [rsi+1], dl
    mov rax, 2
    ret