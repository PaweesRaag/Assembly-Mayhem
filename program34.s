.intel_syntax noprefix
.global _start

_start:
    # Keep the format string pointer in R12.
    mov r12, [rsp+16]

    # This stage introduces %d formatting and helper routines.
    # [rsp+24] contains the next command-line argument after argv[1].

print:
    # Stop at the NUL terminator.
    cmp byte ptr [r12], 0
    je end

    # Check for a backslash escape sequence.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # Check for a percent format sequence.
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
    # "\\n" -> newline.
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
    # "%%" -> literal percent.
    cmp byte ptr [r12+1], 0x25
    je percent

    # "%d" -> parse and print the next decimal argument.
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
    # Create a single newline byte below RSP and write it.
    mov byte ptr [rsp-1], 0x0a
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both source characters: '\\' and 'n'.
    add r12, 2
    jmp print

backslash:
    # Create a literal backslash below RSP and write it.
    mov byte ptr [rsp-1], 0x5c
    mov rsi, rsp
    dec rsi
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both source characters.
    add r12, 2
    jmp print

percent:
    # Create a literal '%' below RSP and write it.
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
    # [rsp+24] is the first decimal argument in this stage.
    mov rdi, [rsp+24]

    # Convert the ASCII decimal string to an integer.
    # atoi returns the integer in RAX.
    call atoi

    # Reserve temporary stack space for itoa's output string.
    sub rsp, 128
    mov rsi, rsp
    mov rdi, rax

    # Convert the integer to ASCII decimal characters.
    # itoa returns the number of bytes written in RAX.
    call itoa

    # write(1, rsp, rax)
    mov rdx, rax
    mov rsi, rsp
    mov rdi, 1
    mov rax, 1
    syscall

    # Restore the stack and skip the "%d" in the format string.
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
# Output: RAX = signed integer
# ---------------------------------------------------------------------------
atoi:
    # Start the accumulator at zero.
    xor rax, rax

    # R8D is the negative-number flag.
    xor r8d, r8d

    # Check for a leading '-'.
    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    mov r8d, 1
    inc rdi

atoi_loop:
    # Load the next character into ECX.
    movzx ecx, byte ptr [rdi]

    # Stop if the byte is below ASCII '0'.
    cmp ecx, 0x30
    jb atoi_done

    # Stop if the byte is above ASCII '9'.
    cmp ecx, 0x39
    ja atoi_done

    # value = value * 10 + digit
    imul rax, rax, 10
    sub ecx, 0x30
    add rax, rcx

    inc rdi
    jmp atoi_loop

atoi_done:
    # Apply the negative sign if needed.
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

    # Negative values take a separate path.
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

    # Write '-' and move the destination forward.
    mov byte ptr [rsi], 0x2D
    inc rsi

    # Convert to a positive magnitude for digit extraction.
    neg rdi

    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    # Divide by 10: quotient in RAX, remainder in RDX.
    xor rdx, rdx
    div rcx

    # Save the remainder so digits can later be written forward.
    push rdx
    inc rbx

    # Continue until the quotient becomes zero.
    cmp rax, 0
    jne itoa_extract

    # Preserve the number of digits.
    mov r8, rbx

itoa_write:
    # Pop one digit, convert 0..9 to ASCII, and store it.
    pop rax
    add al, 0x30

    mov byte ptr [rsi], al
    inc rsi

    dec rbx
    jnz itoa_write

    # Return the numeric digit count.
    mov rax, r8

    # Include the '-' character in the count if necessary.
    cmp r9d, 1
    jne itoa_finish

    add rax, 1

itoa_finish:
    pop rbx
    ret

itoa_zero:
    # Write the single ASCII character '0'.
    mov byte ptr [rsi], 0x30
    mov rax, 1

    pop rbx
    ret
