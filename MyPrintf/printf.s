.intel_syntax noprefix

# Make _start visible to the linker. This program is intended to start
# directly at the ELF entry point instead of going through libc's main().
.global _start

# -----------------------------------------------------------------------------
# _start
# -----------------------------------------------------------------------------
#
# The program is deliberately working close to the process entry state.
# At _start, rsp points at the stack prepared by the Linux kernel:
#
#   [rsp + 0]   = argc
#   [rsp + 8]   = argv[0]
#   [rsp + 16]  = argv[1]
#   [rsp + 24]  = argv[2]
#   ...
#
# In this implementation, r12 is used as a pointer into the format string,
# while r13 is used as an offset into the initial stack arguments. Keeping
# those two pieces of state in callee-saved registers also lets our helper
# routines freely use many of the other general-purpose registers.
# -----------------------------------------------------------------------------
_start:
    # r12 = argv[1], which is the first user-supplied string passed to the
    # program. We treat it as our printf-like format string.
    mov r12, [rsp+16]

    # r13 = 24 = offset of argv[2].
    #
    # The first argument after our format string therefore lives at:
    #   [rsp + 24]
    #
    # Every additional argument is another 8 bytes further down the stack
    # because argv entries are 64-bit pointers.
    mov r13, 24

# -----------------------------------------------------------------------------
# print
# -----------------------------------------------------------------------------
# Main format-string parser.
#
# r12 always points at the current character in the format string.
# The parser handles ordinary characters, backslash escape sequences, and
# percent-format specifiers.
# -----------------------------------------------------------------------------
print:
    # A C string ends at a NUL byte. If we reached it, there is nothing left
    # to print and the program can terminate.
    cmp byte ptr [r12], 0
    je end

    # '\\' introduces an escape sequence in our mini printf implementation.
    # 0x5c is the ASCII value for '\\'.
    cmp byte ptr [r12], 0x5c
    je check_backslash

    # '%' introduces a format specifier such as %d or %s.
    # 0x25 is the ASCII value for '%'.
    cmp byte ptr [r12], 0x25
    je check_percent

    # -------------------------------------------------------------------------
    # Ordinary character
    # -------------------------------------------------------------------------
    # Nothing special was found, so r12 itself is the address of the one byte
    # we want to write.
    mov rsi, r12              # write() buffer = current character
    mov rax, 1                # Linux x86-64 syscall number: write
    mov rdi, 1                # file descriptor 1 = stdout
    mov rdx, 1                # write exactly one byte
    syscall

    # Move to the next format-string character and continue parsing.
    inc r12
    jmp print

# -----------------------------------------------------------------------------
# check_backslash
# -----------------------------------------------------------------------------
# We already know [r12] == '\\'. Examine the next byte to determine whether
# this is a supported escape sequence:
#
#   \n   -> newline
#   \\   -> literal backslash
#   \xHH  -> one byte represented by two hexadecimal digits
# -----------------------------------------------------------------------------
check_backslash:
    # 0x6e = ASCII 'n'
    cmp byte ptr [r12+1], 0x6e
    je newline

    # 0x5c = ASCII '\\'
    cmp byte ptr [r12+1], 0x5c
    je backslash

    # 0x78 = ASCII 'x'
    cmp byte ptr [r12+1], 0x78
    je hex

    # Unknown escape sequence.
    # Rather than silently discarding the '\\', treat it as an ordinary byte
    # and print it literally. We advance by only one character here, so the
    # character after the backslash will be processed normally on the next
    # iteration.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

# -----------------------------------------------------------------------------
# check_percent
# -----------------------------------------------------------------------------
# We already know [r12] == '%'. Inspect the next byte for the supported
# format specifiers:
#
#   %%  -> literal '%'
#   %d  -> signed decimal integer
#   %s  -> NUL-terminated string
# -----------------------------------------------------------------------------
check_percent:
    # 0x25 = ASCII '%'
    cmp byte ptr [r12+1], 0x25
    je percent

    # 0x64 = ASCII 'd'
    cmp byte ptr [r12+1], 0x64
    je decimal

    # 0x73 = ASCII 's'
    cmp byte ptr [r12+1], 0x73
    je string

    # Unknown format specifier.
    # Print the '%' literally instead of attempting to interpret it.
    mov rsi, r12
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    inc r12
    jmp print

# -----------------------------------------------------------------------------
# newline
# -----------------------------------------------------------------------------
# Convert the two-character sequence "\\n" into a single newline byte and
# print it. We use one byte just below the current stack pointer as temporary
# scratch storage.
# -----------------------------------------------------------------------------
newline:
    # ASCII LF (line feed) = 0x0a.
    mov byte ptr [rsp-1], 0x0a

    # rsi must contain the address of the byte we just created.
    lea rsi, [rsp-1]

    # write(1, rsp-1, 1)
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both characters '\\' and 'n'.
    add r12, 2
    jmp print

# -----------------------------------------------------------------------------
# backslash
# -----------------------------------------------------------------------------
# Convert "\\\\" into one literal '\\' byte.
# -----------------------------------------------------------------------------
backslash:
    # ASCII backslash = 0x5c.
    mov byte ptr [rsp-1], 0x5c
    lea rsi, [rsp-1]

    # write(1, rsp-1, 1)
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both backslashes.
    add r12, 2
    jmp print

# -----------------------------------------------------------------------------
# percent
# -----------------------------------------------------------------------------
# Convert "%%" into one literal '%' byte.
# -----------------------------------------------------------------------------
percent:
    # ASCII percent = 0x25.
    mov byte ptr [rsp-1], 0x25
    lea rsi, [rsp-1]

    # write(1, rsp-1, 1)
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume both percent characters.
    add r12, 2
    jmp print

# -----------------------------------------------------------------------------
# decimal
# -----------------------------------------------------------------------------
# Handle %d.
#
# High-level flow:
#   1. Fetch the next argument from the original startup stack.
#   2. Convert its ASCII representation to an integer using atoi.
#      (This implementation expects the argument to be a string.)
#   3. Reserve 128 bytes below rsp as an output buffer.
#   4. Convert the integer back into ASCII with itoa.
#   5. write() the resulting characters.
#   6. Restore rsp and advance to the next format character/argument.
# -----------------------------------------------------------------------------
decimal:
    # r13 points at the current printf argument slot.
    # Dereference it to retrieve the pointer to the decimal string.
    mov rdi, [rsp+r13]

    # atoi returns the numerical value in rax.
    call atoi

    # Reserve a generous temporary buffer for itoa's output.
    # Since atoi/itoa do not receive a standard C stack frame here, this area
    # is simply scratch space owned by this call site.
    sub rsp, 128

    # itoa writes its ASCII output starting at the new rsp.
    mov rsi, rsp

    # Pass the integer returned by atoi to itoa.
    mov rdi, rax
    call itoa

    # itoa returns the number of bytes written in rax.
    # write(1, rsp, rax)
    mov rdx, rax              # byte count
    mov rsi, rsp              # output buffer
    mov rdi, 1                # stdout
    mov rax, 1                # write syscall
    syscall

    # Release the temporary buffer.
    add rsp, 128

    # Consume "%d" in the format string.
    add r12, 2

    # Move to the next printf argument (8-byte pointer-sized slot).
    add r13, 8
    jmp print

# -----------------------------------------------------------------------------
# string
# -----------------------------------------------------------------------------
# Handle %s.
#
# The argument is a pointer to a NUL-terminated string. We first scan the
# string ourselves to determine its length because the Linux write syscall
# requires an explicit byte count; it does not understand C's NUL terminator.
# -----------------------------------------------------------------------------
string:
    # Load the next argument: a pointer to the string to print.
    mov r11, [rsp+r13]

    # write() expects the buffer pointer in rsi.
    mov rsi, r11

    # Start the string length counter at zero.
    xor rdx, rdx

string_length:
    # Inspect string[rdx]. If it is zero, we found the terminator.
    cmp byte ptr [r11+rdx], 0
    je string_write

    # Otherwise count one more byte.
    inc rdx
    jmp string_length

string_write:
    # At this point:
    #   rsi = start of string
    #   rdx = string length
    # Perform write(1, rsi, rdx).
    mov rax, 1
    mov rdi, 1
    syscall

    # Consume "%s" and advance to the next argument.
    add r13, 8
    add r12, 2
    jmp print

# -----------------------------------------------------------------------------
# hex
# -----------------------------------------------------------------------------
# Handle a hexadecimal escape of the form "\\xHH".
#
# Example:
#   \\x41  -> 'A'
#
# The two ASCII hex digits are converted into numeric nibbles, the first is
# shifted left by four bits, and the second is ORed into the low nibble.
# -----------------------------------------------------------------------------
hex:
    # Load the first hex digit (the byte immediately after the 'x').
    mov r11b, byte ptr [r12+2]

    # Convert ASCII [0-9A-Fa-f] to its numeric value 0..15.
    # The result is returned in r11b.
    call hex_digit

    # Zero-extend the first nibble into eax, then move it into the high nibble
    # of the final byte: e.g. 0x4 -> 0x40.
    movzx eax, r11b
    shl eax, 4

    # Load the second hex digit.
    mov r11b, byte ptr [r12+3]
    call hex_digit

    # Convert the second digit and combine it with the first nibble.
    movzx ebx, r11b
    or eax, ebx

    # The assembled byte is now in AL.
    mov byte ptr [rsp-1], al
    lea rsi, [rsp-1]

    # write(1, rsp-1, 1)
    mov rax, 1
    mov rdi, 1
    mov rdx, 1
    syscall

    # Consume the four-character sequence "\\xHH".
    add r12, 4
    jmp print

# -----------------------------------------------------------------------------
# hex_digit
# -----------------------------------------------------------------------------
# Convert one ASCII hexadecimal character into a value 0..15.
#
# Input : r11b = ASCII character
# Output: r11b = numeric nibble
#
# Supported characters:
#   '0'..'9'
#   'A'..'F'
#   'a'..'f'
# -----------------------------------------------------------------------------
hex_digit:
    # First test for ASCII digits 0..9.
    cmp r11b, 0x30            # '0'
    jb not_hex
    cmp r11b, 0x39            # '9'
    jbe digit

    # Next test for uppercase hexadecimal A..F.
    cmp r11b, 0x41            # 'A'
    jb maybe_lower
    cmp r11b, 0x46            # 'F'
    jbe upper

maybe_lower:
    # Finally test lowercase a..f.
    cmp r11b, 0x61            # 'a'
    jb not_hex
    cmp r11b, 0x66            # 'f'
    ja not_hex

    # Convert 'a'..'f' into 10..15:
    #   'a' - 'a' = 0
    #   0 + 10  = 10
    #   ...
    #   'f' - 'a' = 5
    #   5 + 10 = 15
    sub r11b, 0x61
    add r11b, 10
    ret

upper:
    # Same conversion for uppercase A..F.
    #   'A' - 'A' = 0, then +10 => 10
    sub r11b, 0x41
    add r11b, 10
    ret

digit:
    # ASCII digits are contiguous, so subtracting '0' directly maps:
    #   '0' -> 0, '1' -> 1, ..., '9' -> 9
    sub r11b, 0x30
    ret

not_hex:
    # Invalid hex characters are treated as fatal for this implementation.
    jmp end

# -----------------------------------------------------------------------------
# end
# -----------------------------------------------------------------------------
# Exit the process directly with the Linux exit syscall.
#
# syscall ABI:
#   rax = 60  (sys_exit)
#   rdi = exit status
# -----------------------------------------------------------------------------
end:
    mov rax, 60               # sys_exit
    xor rdi, rdi              # exit status = 0
    syscall

# -----------------------------------------------------------------------------
# atoi
# -----------------------------------------------------------------------------
# Convert a NUL-terminated decimal ASCII string to a signed integer.
#
# Input : rdi = pointer to string
# Output: rax = parsed signed integer
#
# Example:
#   "123"  -> 123
#   "-42"  -> -42
#
# The conversion uses the standard recurrence:
#   value = value * 10 + current_digit
#
# r8d acts as a boolean negative flag.
# -----------------------------------------------------------------------------
atoi:
    # Accumulator starts at 0.
    xor rax, rax

    # r8d = 0 means positive; r8d = 1 means the input had a leading '-'.
    xor r8d, r8d

    # Check for a leading minus sign (ASCII '-': 0x2D).
    cmp byte ptr [rdi], 0x2D
    jne atoi_loop

    # Remember that the final result must be negative.
    mov r8d, 1

    # Skip the '-' before processing digits.
    inc rdi

atoi_loop:
    # Load the current character and zero-extend it into ecx.
    movzx ecx, byte ptr [rdi]

    # Anything below ASCII '0' terminates the number.
    cmp ecx, 0x30
    jb atoi_done

    # Anything above ASCII '9' also terminates the number.
    cmp ecx, 0x39
    ja atoi_done

    # Shift the previous decimal value one digit to the left:
    #     old * 10
    imul rax, rax, 10

    # Convert ASCII digit into numeric digit.
    # Example: ASCII '7' (0x37) - 0x30 = 7.
    sub ecx, 0x30

    # Add the new digit to the accumulated value.
    add rax, rcx

    # Advance to the next character.
    inc rdi
    jmp atoi_loop

atoi_done:
    # If a leading '-' was seen, negate the accumulated positive value.
    cmp r8d, 1
    jne atoi_return
    neg rax

atoi_return:
    ret

# -----------------------------------------------------------------------------
# itoa
# -----------------------------------------------------------------------------
# Convert a signed integer into decimal ASCII.
#
# Input : rdi = signed integer
#         rsi = destination buffer
# Output: rax = number of ASCII bytes written
#
# Core idea:
#   repeatedly divide the number by 10.
#   The remainder is the next least-significant decimal digit.
#
# Since division produces digits from right to left, the remainders are pushed
# onto the stack and later popped in reverse order so that the final output is
# left-to-right.
# -----------------------------------------------------------------------------
itoa:
    # Preserve RBX because we use it as the digit counter.
    push rbx

    # Special case: zero has no useful division loop because 0 / 10 = 0.
    cmp rdi, 0
    je itoa_zero

    # Negative numbers need a '-' prefix and a positive magnitude for the
    # repeated division algorithm.
    cmp rdi, 0
    jl itoa_negative

    # Positive-number setup.
    xor rbx, rbx              # digit count = 0
    xor r9d, r9d              # negative flag = 0
    mov rax, rdi              # working value
    mov rcx, 10               # decimal base
    jmp itoa_extract

itoa_negative:
    # Remember that we need to account for a leading '-'.
    mov r9d, 1

    # Write '-' as the first output character.
    mov byte ptr [rsi], 0x2D
    inc rsi

    # Work with the positive magnitude from here on.
    neg rdi

    # Reset digit counter and initialize the division state.
    xor rbx, rbx
    mov rax, rdi
    mov rcx, 10

itoa_extract:
    # DIV operates on the 128-bit integer in RDX:RAX.
    # Clear RDX so the dividend is simply the non-negative value in RAX.
    xor rdx, rdx

    # Unsigned divide RDX:RAX by 10.
    # Afterward:
    #   rax = quotient
    #   rdx = remainder (0..9)
    div rcx

    # Save the remainder. Because division finds the least-significant digit
    # first, the stack naturally reverses the digit order for us.
    push rdx

    # Count one extracted digit.
    inc rbx

    # More digits remain while the quotient is non-zero.
    cmp rax, 0
    jne itoa_extract

    # Save the total digit count so RAX can eventually return it to the caller.
    mov r8, rbx

itoa_write:
    # Retrieve the most-significant remaining digit.
    pop rax

    # Numeric digit 0..9 -> ASCII '0'..'9'.
    add al, 0x30

    # Write it to the destination buffer.
    mov byte ptr [rsi], al
    inc rsi

    # One fewer digit remains on the temporary stack.
    dec rbx
    jnz itoa_write

    # Return the number of numeric digits written.
    mov rax, r8

    # A negative number also wrote one extra '-' byte, so include it in the
    # returned length.
    cmp r9d, 1
    jne itoa_finish
    add rax, 1

itoa_finish:
    # Restore the caller's RBX and return.
    pop rbx
    ret

itoa_zero:
    # The integer 0 is represented by the single ASCII byte '0'.
    mov byte ptr [rsi], 0x30

    # Return length = 1.
    mov rax, 1

    # Restore RBX because the function pushed it on entry.
    pop rbx
    ret
