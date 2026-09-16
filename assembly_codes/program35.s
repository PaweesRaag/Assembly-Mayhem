.intel_syntax noprefix
.global _start

_start:
    # Keep a pointer to the format string in R12.
    mov r12, [rsp+16]

    # R13 tracks which command-line argument supplies the next format value.
    # At process entry, the first argv pointer is at [rsp+8], so the first
    # value after the format string is reached at [rsp+24].
    mov r13, 24

print:
    # Stop at the NUL terminator.
    cmp byte ptr [r12], 0
    je end

    # Check for a backslash escape.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # Check for a percent format specifier.
    cmp byte ptr [r12], 0x25
    je check_percent

    # Normal character -> write one byte to stdout.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

check_backslash:
    # "\\n" -> newline.
    cmp byte ptr [r12+1], 0x6e
    je newline

    # "\\\\" -> literal backslash.
    cmp byte ptr [r12+1], 0x5c
    je backslash

    # Unsupported escape -> emit the backslash literally.
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

    # "%d" -> read the next command-line argument as a decimal integer.
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
    # Create a newline byte just below RSP, then write that byte.
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
    # Create a literal '\\' byte below RSP and print it.
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
    # Create a literal '%' byte below RSP and print it.
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
    # R13 is the stack offset of the command-line argument to consume.
    # First pass: 24 = [rsp+24], then increment by 8 after each %d.
    mov rdi, [rsp+r13]

    # Convert the ASCII decimal string to a signed integer.
    # Return value: RAX = integer.
    call atoi

    # Reserve temporary space for itoa's output string.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax

    # Convert the integer into decimal ASCII characters.
    # itoa returns the character count in RAX.
    call itoa

    # write(1, rsp, rax)
    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    # Restore the original stack pointer.
    add rsp, 128

    # Skip '%d' in the format string.
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

    # R8D acts as a negative-number flag: 0 = positive, 1 = negative.
    xor r8d, r8d

    # Test for a leading '-'.
    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    # Read the next ASCII byte and zero-extend it into ECX.
    movzx ecx, byte ptr [rdi]

    # Anything below '0' terminates the number.
    cmp ecx, 0x30
    jb atoi_done

    # Anything above '9' terminates the number.
    cmp ecx, 0x39
    ja atoi_done

    # Decimal accumulation:
    #     value = value * 10 + (character - '0')
    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    # Apply the sign if the input began with '-'.
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
    # RBX is callee-saved, so preserve its original value.
    push rbx

    # Special case: 0.
    cmp rdi, 0
    je itoa_zero

    # Negative value -> handle sign before extracting digits.
    cmp rdi, 0
    jl itoa_negative

    # Positive number setup.
    xor rbx, rbx
    xor r9d, r9d
    mov rax, rdi
    mov rcx, 10
    jmp itoa_extract

itoa_negative:
    # R9D records that a '-' was written.
    mov r9d, 1

    mov byte ptr [rsi], 0x2D
    inc rsi

    # Convert to positive magnitude for digit extraction.
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    # Divide by 10. RDX receives the remainder (0..9), which is
    # the next digit from right to left.
    xor rdx, rdx
    div rcx

    # Push each remainder so digits can later be popped in forward order.
    push rdx
    inc rbx

    # Continue while the quotient is non-zero.
    cmp rax, 0
    jne itoa_extract

    # Save the original digit count.
    mov r8, rbx

itoa_write:
    # Recover the next digit and convert 0..9 to ASCII.
    pop rax
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    # Return the number of numeric digits.
    mov rax, r8

    # Add one to the count if we emitted a leading '-'.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    pop rbx
    ret

itoa_zero:
    # Output the single character '0'.
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
