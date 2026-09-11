; Program 31 — Print a NUL-terminated string
; argv[1] is treated as a pointer to a string.
; Each byte is written individually to stdout until the NUL terminator.

.intel_syntax noprefix
.global _start

_start:
    ; Load argv[1] into RSI; RSI acts as the string cursor.
    mov rsi, [rsp+16]

print:
    ; Stop when the current byte is the string terminator.
    cmp byte ptr [rsi], 0
    je end

    ; write(stdout, current_byte, 1)
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    ; Advance to the next character.
    inc rsi
    jmp print

end:
    ; exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall
