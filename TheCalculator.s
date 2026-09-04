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
; Numbers are read as decimal strings with atoi(), and the
; result is converted back to text with itoa() before write().
; ============================================================

_start:
    ; argc is stored at [rsp].
    ; argc == 3 means unary:  prog OP A
    ; otherwise this program treats it as binary: prog A OP B
    mov rdi, [rsp]
    cmp rdi, 3
    je unary

binary:
    ; Convert argv[1] (left operand) from text to integer.
    mov rdi, [rsp+16]
    call atoi
    mov rbx, rax                  ; save left operand

    ; Convert argv[3] (right operand) from text to integer.
    mov rdi, [rsp+32]
    call atoi

    ; argv[2] is a pointer to the operator string.
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
    ; Unary form is: prog OP A
    ; argv[1] = operator, argv[2] = operand.
    mov r11, [rsp+16]

    ; Convert argv[2] to an integer.
    mov rdi, [rsp+24]
    call atoi

    ; '~' performs bitwise NOT.
    cmp byte ptr [r11], 0x7E      ; '~'
    je not_operation

    ; '-' performs arithmetic negation.
    cmp byte ptr [r11], 0x2D      ; '-'
    je nega

    ; Unsupported unary operator.
    jmp end

function:
    ; Reserve scratch space for the decimal result.
    sub rsp, 128
    mov rsi, rsp                  ; RSI = output buffer
    mov rdi, rax                  ; RDI = integer to format
    call itoa

    ; write(1, buffer, length)
    mov rdx, rax                  ; number of bytes returned by itoa
    mov rdi, 1                    ; stdout
    mov rsi, rsp                  ; buffer
    mov rax, 1                    ; SYS_write
    syscall

    ; Successful exit: status 0.
    xor rdi, rdi

end:
    ; exit(status)
    mov rax, 60                   ; SYS_exit
    syscall


; ============================================================
; atoi
; Input : RDI = pointer to a decimal string
; Output: RAX = signed integer value
;
; Supports an optional leading '-'. Parsing stops at the first
; byte outside the ASCII digit range '0'..'9'.
; ============================================================
atoi:
    xor rax, rax                  ; accumulated value = 0
    xor r8d, r8d                  ; negative flag = 0

    ; Check for a leading '-'.
    cmp byte ptr [rdi], 0x2D      ; '-'
    jne atoi_loop

    mov r8d, 1                    ; mark as negative
    inc rdi                       ; skip '-'

atoi_loop:
    ; Load the current character as an unsigned byte.
    movzx ecx, byte ptr [rdi]

    ; Stop if character is below '0'.
    cmp ecx, 0x30
    jb atoi_done

    ; Stop if character is above '9'.
    cmp ecx, 0x39
    ja atoi_done

    ; value = value * 10 + digit
    imul rax, rax, 10
    sub ecx, 0x30                 ; ASCII digit -> numeric digit
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    ; Apply the sign if a leading '-' was present.
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
; Uses the stack to reverse the digits, because repeated division
; by 10 produces digits from least-significant to most-significant.
; Supports negative values and zero.
; ============================================================
itoa:
    ; RBX is callee-saved, so preserve it.
    push rbx

    ; Special case: zero.
    cmp rdi, 0
    je itoa_zero

    ; Negative numbers get a leading '-'.
    cmp rdi, 0
    jl itoa_negative

    ; Positive number.
    xor rbx, rbx                  ; digit count = 0
    xor r9d, r9d                  ; negative flag = 0
    mov rax, rdi                  ; working value
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    mov r9d, 1                    ; remember that '-' is needed

    ; Write '-' first and advance the buffer pointer.
    mov byte ptr [rsi], 0x2D      ; '-'
    inc rsi

    ; Work with the positive magnitude.
    neg rdi

    xor rbx, rbx                  ; digit count = 0
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    ; Divide the remaining value by 10.
    ; Quotient -> RAX, remainder -> RDX.
    xor rdx, rdx
    div rcx

    ; Store the remainder (next decimal digit) on the stack.
    push rdx
    inc rbx

    ; Continue until the quotient reaches zero.
    cmp rax, 0
    jne itoa_extract

    ; Preserve the digit count while RBX is consumed by the write loop.
    mov r8, rbx

itoa_write:
    ; Digits were pushed in reverse order, so pop them to restore
    ; the correct left-to-right decimal order.
    pop rax
    add al, 0x30                  ; numeric digit -> ASCII

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    ; Return the number of digits written.
    mov rax, r8

    ; Add one byte to the length if a '-' was written.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    ; Restore the caller's RBX.
    pop rbx
    ret

itoa_zero:
    ; Zero is represented by exactly one byte: '0'.
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret


; ============================================================
; Binary operations
; After the two atoi calls:
;   RBX = left operand
;   RAX = right operand
; The result is left in RAX for the common output path.
; ============================================================
add:
    add rax, rbx                  ; right + left
    jmp function

sub:
    sub rbx, rax                  ; left - right
    mov rax, rbx
    jmp function

mul:
    imul rax, rbx                 ; left * right
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
; RAX already contains the operand from atoi().
; ============================================================
not_operation:
    not rax                       ; bitwise NOT
    jmp function

nega:
    neg rax                       ; arithmetic negation
    jmp function
