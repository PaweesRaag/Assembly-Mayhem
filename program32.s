.intel_syntax noprefix
.global _start

_start:
    # argv[1] is at [rsp+16] at process entry.
    # Keep a pointer to the current character in RSI.
    mov rsi, [rsp+16]

print:
    # Stop at the NUL terminator.
    cmp byte ptr [rsi], 0
    je end

    # Detect the two-byte escape sequence "\\n".
    # 0x5c = '\\' and 0x6e = 'n'.
    cmp byte ptr [rsi], 0x5c
    jne normal
    cmp byte ptr [rsi+1], 0x6e
    je newline

normal:
    # write(1, rsi, 1)
    # rax = 1  -> write syscall
    # rdi = 1  -> stdout
    # rsi      -> address of the byte
    # rdx = 1  -> write one byte
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Move to the next character.
    inc rsi
    jmp print

end:
    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

newline:
    # Replace the 'n' in "\\n" with an actual newline byte.
    mov byte ptr [rsi+1], 0x0a
    inc rsi
    jmp print
