.intel_syntax noprefix

.global _start

; ============================================================
; TheCalculator
; A small command-line calculator written in x86-64 assembly.
;
; Supported forms:
;   prog A + B
;   prog A - B
;   prog A * B
;   prog A ^ B    ; bitwise XOR
;   prog A | B    ; bitwise OR
;   prog A & B    ; bitwise AND
;   prog - A      ; unary negation
;   prog ~ A      ; bitwise NOT
;
; Numbers are parsed from decimal strings with atoi(). The result
; is converted back to signed decimal text with itoa() and sent
; to standard output using the Linux write syscall.
; ============================================================

_start:
    ; argc is stored at [rsp].
    ; argc == 3 means unary form: prog OP A.
    mov rdi, [rsp]
    cmp rdi, 3
    je unary

binary:
    ; argv[1] -> left operand.
    mov rdi, [rsp+16]
    call atoi
    mov rbx, rax

    ; argv[3] -> right operand.
    mov rdi, [rsp+32]
    call atoi

    ; argv[2] -> operator string.
    mov r11, [rsp+24]

    ; Dispatch based on the operator character.
    cmp byte ptr [r11], 0x2B      ; '+'
    je add

    cmp byte ptr [r11], 0x2D      ; '-'
    je sub

    cmp byte ptr [r11], 0x2A      ; '*'
    je mul

    cmp byte ptr [r11], 0x5E      ; '^'
    je xor_operation

    cmp byte ptr [r11], 0x7C      ; '|'
    je or_operation

    cmp byte ptr [r11], 0x26      ; '&'
    je and_operation

    ; Unsupported operator.
    jmp end

unary:
    ; Unary form: prog OP A.
    ; argv[1] = operator, argv[2] = operand.
    mov r11, [rsp+16]

    mov rdi, [rsp+24]
    call atoi

    ; Bitwise NOT.
    cmp byte ptr [r11], 0x7E      ; '~'
    je not_operation

    ; Arithmetic negation.
    cmp byte ptr [r11], 0x2D      ; '-'
    je nega

    ; Unsupported unary operator.
    jmp end

function:
    ; Reserve scratch space for the decimal output.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax
    call itoa

    ; write(1, buffer, length)
    mov rdx, rax
    mov rdi, 1
    mov rsi, rsp
    mov rax, 1
    syscall

    ; Successful exit status = 0.
    xor rdi, rdi

end:
    ; exit(status)
    mov rax, 60
    syscall


; ============================================================
; atoi
; Input : RDI = pointer to signed decimal string
; Output: RAX = signed integer value
;
; Supports an optional leading '-'. Parsing stops when the next
; byte is outside the ASCII range '0'..'9'.
; ============================================================
atoi:
    xor rax, rax                  ; accumulated value = 0
    xor r8d, r8d                  ; negative flag = 0

    ; Check for a leading '-'.
    cmp byte ptr [rdi], 0x2D      ; '-'
    jne atoi_loop

    mov r8d, 1                    ; mark number as negative
    inc rdi                       ; skip '-'

atoi_loop:
    ; Load the current ASCII character.
    movzx ecx, byte ptr [rdi]

    ; Accept only '0'..'9'.
    cmp ecx, 0x30
    jb atoi_done

    cmp ecx, 0x39
    ja atoi_done

    ; value = value * 10 + digit
    imul rax, rax, 10
    sub ecx, 0x30                 ; ASCII -> numeric digit
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    ; Apply the sign if required.
    cmp r8d, 1
    jne atoi_return

    neg rax

atoi_return:
    ret


; ============================================================
; itoa
; Input : RDI = signed integer
;         RSI = destination buffer
; Output: RAX = number of bytes written
;
; Decimal digits are produced from least-significant to most-
; significant. They are temporarily pushed onto the stack and
; then popped to write them in the correct order.
; ============================================================
itoa:
    ; RBX is callee-saved, so preserve it.
    push rbx

    ; Special case: zero.
    cmp rdi, 0
    je itoa_zero

    ; Handle negative values separately.
    cmp rdi, 0
    jl itoa_negative

    ; Positive value.
    xor rbx, rbx                  ; digit count = 0
    xor r9d, r9d                  ; negative flag = 0
    mov rax, rdi
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    mov r9d, 1                    ; remember the '-' sign

    ; Write the sign before the digits.
    mov byte ptr [rsi], 0x2D      ; '-'
    inc rsi

    ; Work with the positive magnitude.
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    ; Divide by 10:
    ;   RAX = quotient
    ;   RDX = remainder (next decimal digit)
    xor rdx, rdx
    div rcx

    ; Save the digit because extraction happens in reverse order.
    push rdx
    inc rbx

    cmp rax, 0
    jne itoa_extract

    ; Preserve digit count while RBX is consumed by the write loop.
    mov r8, rbx

itoa_write:
    ; Restore the digits from most-significant to least-significant.
    pop rax
    add al, 0x30                 ; numeric digit -> ASCII

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    mov rax, r8

    ; Include '-' in the returned length for negative values.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    pop rbx
    ret

itoa_zero:
    mov byte ptr [rsi], 0x30     ; '0'
    mov rax, 1

    pop rbx
    ret


; ============================================================
; Binary operations
; After atoi():
;   RBX = left operand
;   RAX = right operand
; Each handler leaves the final result in RAX.
; ============================================================
add:
    add rax, rbx
    jmp function

sub:
    sub rbx, rax                 ; left - right
    mov rax, rbx
    jmp function

mul:
    imul rax, rbx
    jmp function

xor_operation:
    xor rax, rbx
    jmp function

or_operation:
    or rax, rbx
    jmp function

and_operation:
    and rax, rbx
    jmp function


; ============================================================
; Unary operations
; RAX already contains the operand returned by atoi().
; ============================================================
not_operation:
    not rax                      ; bitwise NOT
    jmp function

nega:
    neg rax                      ; arithmetic negation
    jmp function
