.intel_syntax noprefix
.global _start

_start:
    # Keep argv[1] / the format string in R12 so the other registers
    # can be reused for syscall arguments.
    mov r12, [rsp+16]

print:
    # Stop when we reach the NUL terminator.
    cmp byte ptr [r12], 0
    je end

    # A backslash may introduce an escape sequence.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # A percent sign may introduce a formatting sequence.
    cmp byte ptr [r12], 0x25
    je check_percent

    # Normal character -> write one byte to stdout.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Advance one character.
    inc r12
    jmp print

check_backslash:
    # "\\n" -> actual newline.
    cmp byte ptr [r12+1], 0x6e
    je newline

    # "\\\\" -> literal backslash.
    cmp byte ptr [r12+1], 0x5c
    je backslash

    # Unsupported escape -> print the backslash literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_percent:
    # "%%" -> literal percent character.
    cmp byte ptr [r12+1], 0x25
    je percent

    # Unsupported percent sequence -> print '%' literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

newline:
    # Construct a one-byte newline below RSP and print it.
    mov byte ptr [rsp-1], 0x0a
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both characters in "\\n".
    add r12, 2
    jmp print

backslash:
    # Construct a literal backslash below RSP and print it.
    mov byte ptr [rsp-1], 0x5c
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both characters in "\\\\".
    add r12, 2
    jmp print

percent:
    # Construct a literal '%' below RSP and print it.
    mov byte ptr [rsp-1], 0x25
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both characters in "%%".
    add r12, 2
    jmp print

end:
    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
