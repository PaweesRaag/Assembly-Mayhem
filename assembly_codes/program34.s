.intel_syntax noprefix
.global _start

_start:
    # r12 = pointer to the format string / first argument.
    mov r12, [rsp+16]

    # r11 = value found at the current stack location [rsp].
    # This is kept as part of the stage's exploration of process-entry state.
    mov r11, [rsp]

print:
    # Stop at the string's null terminator.
    cmp byte ptr [r12], 0
    je end

    # Check for supported backslash escapes.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # Check for supported percent escapes.
    cmp byte ptr [r12], 0x25
    je check_percent

    # Normal character -> write one byte.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_backslash:
    # "\\n" means an actual newline.
    cmp byte ptr [r12+1], 0x6e
    je newline

    # "\\\\" means a literal backslash.
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
    # "%%" means a literal percent sign.
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
    # Construct one newline byte below RSP and write it.
    mov byte ptr [rsp-1], 0x0a
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both characters in "\\n".
    add r12, 2
    jmp print

backslash:
    # Construct one literal backslash below RSP and write it.
    mov byte ptr [rsp-1], 0x5c
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2
    jmp print

percent:
    # Construct one literal '%' below RSP and write it.
    mov byte ptr [rsp-1], 0x25
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    add r12, 2
    jmp print

decimal:
    # The %d argument is located at [rsp+24] in this version.
    mov rdi, [rsp+24]

    # Convert the ASCII decimal string to an integer in RAX.
    call atoi

    # Reserve 128 bytes for the temporary output buffer.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax

    # Convert the integer in RDI to decimal ASCII at [RSP].
    call itoa

    # itoa returns the number of output bytes in RAX.
    # write(1, rsp, rax)
    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    # Release the temporary buffer and skip '%d'.
    add rsp, 128
    add r12, 2
    jmp print

end:
    # exit(0)
    mov rax, 60
    xor rdi, rdi
    syscall

# ---------------------------------------------------------------------------
# atoi
# ---------------------------------------------------------------------------
# Input:  RDI -> NUL-terminated decimal string
# Output: RAX = signed integer value
# ---------------------------------------------------------------------------
atoi:
    # Accumulator = 0.
    xor rax, rax

    # R8D is used as the negative-number flag.
    xor r8d, r8d

    # Check for a leading '-'.
    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    # Load the next character as an unsigned byte.
    movzx ecx, byte ptr [rdi]

    # Stop if it is below '0'.
    cmp ecx, 0x30
    jb atoi_done

    # Stop if it is above '9'.
    cmp ecx, 0x39
    ja atoi_done

    # accumulator = accumulator * 10 + digit
    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    # Apply the negative sign if the flag was set.
    cmp r8d, 1
    jne atoi_return

    neg rax

atoi_return:
    ret

# ---------------------------------------------------------------------------
# itoa
# ---------------------------------------------------------------------------
# Input:  RDI = signed integer
#         RSI = output buffer
# Output: RAX = number of bytes written
# ---------------------------------------------------------------------------
itoa:
    # RBX is callee-saved, so preserve it.
    push rbx

    # Special case: zero.
    cmp rdi, 0
    je itoa_zero

    # Negative numbers take a separate path.
    cmp rdi, 0
    jl itoa_negative

    # Positive number setup.
    xor rbx, rbx
    xor r9d, r9d
    mov rax, rdi
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    # Record that a '-' was emitted.
    mov r9d, 1

    mov byte ptr [rsi], 0x2D
    inc rsi

    # Work with the magnitude of the number.
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    # Divide by 10 to obtain the next decimal digit.
    xor rdx, rdx
    div rcx

    # The remainder is one digit. Push it so digits can later be
    # popped in reverse order, producing the correct left-to-right string.
    push rdx
    inc rbx

    # Continue until the quotient becomes zero.
    cmp rax, 0
    jne itoa_extract

    mov r8, rbx

itoa_write:
    # Restore one digit and convert 0..9 into ASCII '0'..'9'.
    pop rax
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    # Return the number of digits written.
    mov rax, r8

    # If the original value was negative, count the leading '-'.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    pop rbx
    ret

itoa_zero:
    # Write the one-character representation of zero.
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
