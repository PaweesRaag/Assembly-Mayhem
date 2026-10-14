.intel_syntax noprefix
.global itoa
# Convert unsigned integer 0..99 to ASCII without a leading zero.
# Input: RDI=value, RSI=buffer; output RAX=number of characters (1 or 2).
itoa:
    mov rax, rdi
    xor rdx, rdx
    mov rcx, 10
    div rcx
    cmp rax, 0
    je Single
    add rax, 0x30
    add rdx, 0x30
    mov BYTE PTR [rsi], al     # Write tens.
    mov BYTE PTR [rsi+1], dl   # Write ones.
    mov rax, 2
    jmp end
Single:
    cmp rdx, 0
    je Zero
    add rdx, 0x30
    mov BYTE PTR [rsi], dl
    mov rax, 1
    jmp end
Zero:
    mov BYTE PTR [rsi], 0x30   # Special case: write '0'.
    mov rax, 1
end:
    ret