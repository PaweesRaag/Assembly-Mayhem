; Program 26 — Addition with input operator validation
; Read:  operand1 + operand2
; Convert both operands with atoi, add them, convert the result with itoa,
; and write the resulting decimal string to stdout.

.intel_syntax noprefix
.global _start

_start:
    ; argv[2] contains the operator string.
    mov rdi, [rsp+24]
    ; Accept only '+' for this version.
    cmp byte ptr [rdi], 0x2B
    jne end

    ; Parse argv[1] as the left operand.
    mov rdi, [rsp+16]
    call atoi
    mov rbx, rax              ; Preserve left operand across second atoi.

    ; Parse argv[3] as the right operand.
    mov rdi, [rsp+32]
    call atoi

    ; RAX = right operand, RBX = left operand.
    add rax, rbx              ; Compute left + right.

    ; Reserve 128 bytes for the decimal output buffer.
    sub rsp, 128
    mov rsi, rsp              ; Output buffer.
    mov rdi, rax              ; Value to convert.
    call itoa                  ; Return length in RAX.

    ; write(stdout, buffer, length)
    mov rdx, rax
    mov rdi, 1
    mov rsi, rsp
    mov rax, 1
    syscall

    ; Exit successfully.
    xor rdi, rdi

end:
    ; exit(status)
    mov rax, 60
    syscall

; ---------------------------------------------------------------------------
; atoi
; Convert a signed decimal string to an integer.
; RDI = pointer to string
; RAX = resulting integer
; ---------------------------------------------------------------------------
atoi:
    xor rax, rax              ; Accumulator.
    xor r8d, r8d              ; Sign flag: 1 = negative.

    cmp byte ptr [rdi], 0x2D   ; Leading '-'.
    jne atoi_loop

    mov r8d, 1
    inc rdi                   ; Skip '-'.

atoi_loop:
    movzx ecx, byte ptr [rdi] ; Load current character.

    cmp ecx, 0x30             ; Below '0'?
    jb atoi_done
    cmp ecx, 0x39             ; Above '9'?
    ja atoi_done

    imul rax, rax, 10         ; accumulator *= 10
    sub ecx, 0x30             ; ASCII digit -> numeric digit
    add rax, rcx              ; accumulator += digit

    inc rdi
    jmp atoi_loop

atoi_done:
    cmp r8d, 1
    jne atoi_return

    neg rax                   ; Apply negative sign.

atoi_return:
    ret

; ---------------------------------------------------------------------------
; itoa
; Convert signed integer to decimal ASCII.
; RDI = integer
; RSI = output buffer
; RAX = number of output bytes
; ---------------------------------------------------------------------------
itoa:
    push rbx                  ; Preserve callee-saved RBX.

    cmp rdi, 0
    je itoa_zero
    jl itoa_negative

    xor rbx, rbx              ; Digit count.
    xor r9d, r9d              ; Negative flag.
    mov rax, rdi
    mov rcx, 10

    jmp itoa_extract

itoa_negative:
    mov r9d, 1
    mov byte ptr [rsi], 0x2D  ; Write '-'.
    inc rsi
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    xor rdx, rdx              ; Required before unsigned div.
    div rcx                   ; RAX = quotient, RDX = remainder.
    push rdx                  ; Save one decimal digit.
    inc rbx

    cmp rax, 0
    jne itoa_extract

    mov r8, rbx               ; Preserve digit count.

itoa_write:
    pop rax                   ; Retrieve next digit in reverse order.
    add al, 0x30              ; Numeric digit -> ASCII.
    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    mov rax, r8               ; Return digit count.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1                ; Account for leading '-'.

itoa_finish:
    pop rbx
    ret

itoa_zero:
    mov byte ptr [rsi], 0x30
    mov rax, 1
    pop rbx
    ret
