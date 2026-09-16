.intel_syntax noprefix
.global _start

_start:
    # Keep the format string pointer in R12.
    mov r12, [rsp+16]

    # R13 tracks the stack offset of the next command-line argument.
    # At process entry:
    #   [rsp]    = argc
    #   [rsp+8]  = argv[0]
    #   [rsp+16] = argv[1] (format string)
    #   [rsp+24] = argv[2] (first value for %d)
    # The first data argument therefore starts at offset 24.
    mov r13, 24

print:
    # Stop when the format string reaches its NUL terminator.
    cmp byte ptr [r12], 0
    je end

    # Check for an escape sequence beginning with '\\'.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # Check for a formatting sequence beginning with '%'.
    cmp byte ptr [r12], 0x25
    je check_percent

    # Normal character -> write exactly one byte.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

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
    # "%%" -> literal percent sign.
    cmp byte ptr [r12+1], 0x25
    je percent

    # "%d" -> parse the next command-line argument as a signed integer.
    cmp byte ptr [r12+1], 0x64
    je decimal

    # Unsupported percent sequence -> print '%' literally.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

newline:
    # Place an actual newline byte just below RSP.
    mov byte ptr [rsp-1], 0x0a
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume the two source characters '\\' and 'n'.
    add r12, 2
    jmp print

backslash:
    # Place a literal backslash below RSP and print it.
    mov byte ptr [rsp-1], 0x5c
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both characters of "\\\\".
    add r12, 2
    jmp print

percent:
    # Place a literal '%' below RSP and print it.
    mov byte ptr [rsp-1], 0x25
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both '%' characters.
    add r12, 2
    jmp print

decimal:
    # R13 points to the next command-line argument to consume.
    # First %d uses [rsp+24], then R13 is increased by 8 for the next one.
    mov rdi, [rsp+r13]

    # Convert the argument's ASCII representation to a signed integer.
    # atoi returns the integer in RAX.
    call atoi

    # Reserve temporary stack space for the ASCII output buffer.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax

    # Convert the integer into decimal ASCII characters.
    # itoa returns the output length in RAX.
    call itoa

    # write(1, rsp, rax)
    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    # Restore the stack pointer.
    add rsp, 128

    # Skip "%d" in the format string.
    add r12, 2

    # Advance to the next argv value for the next %d.
    add r13, 8

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
# Output: RAX = signed integer
# ---------------------------------------------------------------------------
atoi:
    # Start the accumulated integer at zero.
    xor rax, rax

    # R8D = 1 when the original string began with '-'.
    xor r8d, r8d

    # Check for a leading minus sign.
    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    # Read the next character as an unsigned byte.
    movzx ecx, byte ptr [rdi]

    # Stop if it is below ASCII '0'.
    cmp ecx, 0x30
    jb atoi_done

    # Stop if it is above ASCII '9'.
    cmp ecx, 0x39
    ja atoi_done

    # value = value * 10 + (character - '0')
    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    # Apply the negative sign if necessary.
    cmp r8d, 1
    jne atoi_return

    neg rax

atoi_return:
    ret

# ---------------------------------------------------------------------------
# itoa
# ---------------------------------------------------------------------------
# Input:  RDI = signed integer
#         RSI = destination buffer
# Output: RAX = number of bytes written
# ---------------------------------------------------------------------------
itoa:
    # RBX is callee-saved, so preserve it before using it as a counter.
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
    # Remember that a '-' was written.
    mov r9d, 1

    # Write the sign character first.
    mov byte ptr [rsi], 0x2D
    inc rsi

    # Work with the positive magnitude while extracting digits.
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    # Divide by 10. The quotient stays in RAX and the remainder in RDX.
    xor rdx, rdx
    div rcx

    # The remainder is the next digit from right to left.
    # Push it so we can later pop digits in the correct order.
    push rdx
    inc rbx

    # Continue until the quotient reaches zero.
    cmp rax, 0
    jne itoa_extract

    # Preserve the number of numeric digits.
    mov r8, rbx

itoa_write:
    # Recover one digit and turn 0..9 into ASCII '0'..'9'.
    pop rax
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    # Return the number of numeric digits written.
    mov rax, r8

    # Include the leading '-' in the count when present.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    pop rbx
    ret

itoa_zero:
    # The string representation of zero is exactly one byte: '0'.
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
