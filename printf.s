.intel_syntax noprefix
.global _start

; Custom printf-like formatter.
; r12 = current position in argv[1] format string.
; r13 = stack offset of the next printf argument (starts at argv[2]).
; The formatter supports literal bytes, \n, \\, %%, %d, %s, and \xNN.

_start:
    mov r12, [rsp+16]          ; r12 = format string (argv[1])
    mov r13, 24                ; [rsp+24] = argv[2], first format argument

print:
    cmp byte ptr [r12], 0      ; End of format string?
    je end

    ; Backslash starts an escape sequence.
    cmp byte ptr [r12], 0x5c   ; '\\'
    je check_backslash

    ; Percent starts a format marker or escaped percent.
    cmp byte ptr [r12], 0x25   ; '%'
    je check_percent

    ; Ordinary literal byte: write it directly.
    mov rsi, r12
    mov rax, 1                 ; write syscall
    mov rdi, 1                 ; stdout
    mov rdx, 1                 ; one byte
    syscall

    inc r12
    jmp print

check_backslash:
    cmp byte ptr [r12+1], 0x6e ; '\\n'
    je newline

    cmp byte ptr [r12+1], 0x5c ; '\\\\'
    je backslash

    cmp byte ptr [r12+1], 0x78 ; '\\x'
    je hex

    ; Unknown escape: print the backslash literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_percent:
    cmp byte ptr [r12+1], 0x25 ; '%%'
    je percent

    cmp byte ptr [r12+1], 0x64 ; '%d'
    je decimal

    cmp byte ptr [r12+1], 0x73 ; '%s'
    je string

    ; Unknown marker: print '%' literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

newline:
    mov byte ptr [rsp-1], 0x0a ; materialize newline byte
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2               ; consume '\\n'
    jmp print

backslash:
    mov byte ptr [rsp-1], 0x5c ; materialize '\\'
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2               ; consume '\\\\'
    jmp print

percent:
    mov byte ptr [rsp-1], 0x25 ; materialize '%'
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2               ; consume '%%'
    jmp print

decimal:
    ; Convert the next argv string to a signed integer.
    mov rdi, [rsp+r13]
    call atoi

    ; Reserve scratch space for signed itoa output.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax
    call itoa

    ; itoa returns output length in rax.
    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    ; Restore stack and advance to the next format/argument.
    add rsp, 128
    add r12, 2
    add r13, 8

    jmp print

string:
    ; r11 = pointer to the next string argument.
    mov r11, [rsp+r13]
    mov rsi, r11
    xor rdx, rdx              ; rdx = string length

string_length:
    cmp byte ptr [r11+rdx], 0
    je string_write

    inc rdx
    jmp string_length

string_write:
    mov rax, 1
    mov rdi, 1
    syscall

    add r13, 8                ; consume one argv value
    add r12, 2                ; consume '%s'

    jmp print

hex:
    ; Convert first hex digit (r12+2) to a nibble.
    mov r11b, byte ptr [r12+2]
    call hex_digit

    movzx eax, r11b
    shl eax, 4                ; high nibble

    ; Convert second hex digit (r12+3) to a nibble.
    mov r11b, byte ptr [r12+3]
    call hex_digit

    movzx ebx, r11b
    or eax, ebx               ; combine high and low nibbles

    ; Write the resulting arbitrary byte.
    mov byte ptr [rsp-1], al
    lea rsi, [rsp-1]

    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 4                ; consume '\\xNN'
    jmp print

; Convert one ASCII hex character in r11b to a 0..15 nibble.
hex_digit:
    cmp r11b, 0x30            ; '0'
    jb not_hex

    cmp r11b, 0x39            ; '9'
    jbe digit

    cmp r11b, 0x41            ; 'A'
    jb maybe_lower

    cmp r11b, 0x46            ; 'F'
    jbe upper

maybe_lower:
    cmp r11b, 0x61            ; 'a'
    jb not_hex

    cmp r11b, 0x66            ; 'f'
    ja not_hex

    sub r11b, 0x61
    add r11b, 10
    ret

upper:
    sub r11b, 0x41
    add r11b, 10
    ret

digit:
    sub r11b, 0x30
    ret

not_hex:
    jmp end

end:
    mov rax, 60               ; exit syscall
    xor rdi, rdi              ; status = 0
    syscall

; Convert a signed decimal string to an integer.
; RDI = pointer to string, RAX = signed result.
atoi:
    xor rax, rax              ; accumulated value
    xor r8d, r8d              ; negative flag

    cmp byte ptr [rdi], 0x2D  ; leading '-'
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    movzx ecx, byte ptr [rdi]

    cmp ecx, 0x30
    jb atoi_done

    cmp ecx, 0x39
    ja atoi_done

    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    cmp r8d, 1
    jne atoi_return

    neg rax

atoi_return:
    ret

; Convert a signed integer to decimal text.
; RDI = signed value, RSI = output buffer, RAX = byte count.
itoa:
    push rbx

    cmp rdi, 0
    je itoa_zero

    cmp rdi, 0
    jl itoa_negative

    xor rbx, rbx              ; digit count
    xor r9d, r9d              ; sign flag = 0
    mov rax, rdi
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    mov r9d, 1                ; remember sign

    mov byte ptr [rsi], 0x2D  ; write '-'
    inc rsi

    neg rdi                   ; work with magnitude

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    xor rdx, rdx
    div rcx                   ; quotient -> rax, remainder -> rdx

    push rdx                  ; save next decimal digit
    inc rbx

    cmp rax, 0
    jne itoa_extract

    mov r8, rbx               ; save digit count

itoa_write:
    pop rax
    add al, 0x30              ; 0..9 -> ASCII

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    mov rax, r8

    cmp r9d, 1
    jne itoa_finish

    add rax, 1                ; include '-'

itoa_finish:
    pop rbx
    ret

itoa_zero:
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
