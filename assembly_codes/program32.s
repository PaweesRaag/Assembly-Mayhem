.intel_syntax noprefix
.global _start

_start:
    # The stack at process entry contains argc, then argv pointers.
    # [rsp+16] is the first user-supplied argument: argv[0] is at [rsp+8].
    mov rsi, [rsp+16]

print:
    # Stop when we reach the null terminator of the string.
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
    # rax = syscall number for write
    # rdi = stdout file descriptor
    # rsi = address of one byte
    # rdx = number of bytes
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Advance to the next character.
    inc rsi
    jmp print

end:
    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

newline:
    # Replace the 'n' byte of "\\n" with an actual newline byte.
    # Then move past both characters and continue printing.
    mov byte ptr [rsi+1], 0x0a
    inc rsi
    jmp print
