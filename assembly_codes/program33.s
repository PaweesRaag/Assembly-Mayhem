.intel_syntax noprefix
.global _start

_start:
    # Keep the current character pointer in R12 so the other registers
    # can be reused for syscall arguments and helper routines.
    mov r12, [rsp+16]

print:
    # End of the string?
    cmp byte ptr [r12], 0
    je end

    # A backslash may introduce an escape sequence such as "\\n" or "\\\\".
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # A percent sign may introduce a formatting sequence such as "%%".
    cmp byte ptr [r12], 0x25
    je check_percent

    # Normal character: write one byte to stdout.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_backslash:
    # "\\n" -> newline
    cmp byte ptr [r12+1], 0x6e
    je newline

    # "\\\\" -> literal backslash
    cmp byte ptr [r12+1], 0x5c
    je backslash

    # If the backslash is not one of the supported sequences,
    # print it literally and advance by one byte.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_percent:
    # "%%" -> literal percent sign
    cmp byte ptr [r12+1], 0x25
    je percent

    # Unsupported percent sequence: print the percent character literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

newline:
    # Build a one-byte newline on the stack and print it.
    # [rsp-1] is one byte below the current stack pointer.
    mov byte ptr [rsp-1], 0x0a
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both bytes of "\\n".
    add r12, 2
    jmp print

backslash:
    # Build a one-byte literal backslash on the stack and print it.
    mov byte ptr [rsp-1], 0x5c
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both bytes of "\\\\".
    add r12, 2
    jmp print

percent:
    # Build a one-byte literal '%' on the stack and print it.
    mov byte ptr [rsp-1], 0x25
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Skip both bytes of "%%".
    add r12, 2
    jmp print

end:
    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
