# Call a function pointer, then write 128 stack-relative bytes to stdout.
# Assumption: the intended buffer exists and is readable at [RSP-0x88]
# after the callback returns. This address is challenge-specific, not generic.
.intel_syntax noprefix
.global solve
solve:
    call rdi                      # Run callback; CALL pushes a return address.
    lea rsi, [rsp-0x88]            # Form buffer address below current RSP.
    mov rdi, 1                     # stdout file descriptor.
    mov rdx, 128                   # Byte count.
    mov rax, 1                     # SYS_write on Linux x86-64.
    syscall                        # Attempt to write the buffer.
    ret