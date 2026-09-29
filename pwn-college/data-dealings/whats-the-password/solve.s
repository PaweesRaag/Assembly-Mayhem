# solve.s — write to stdout and exit
#
# Purpose:
#   This is a minimal Linux x86-64 syscall example.
#   It demonstrates the raw syscall interface rather than calling a
#   libc wrapper such as write() or exit().
#
# Calling convention used by Linux x86-64 syscalls:
#   RAX = syscall number
#   RDI = first argument
#   RSI = second argument
#   RDX = third argument
#
# This function receives:
#   RDI = file descriptor
#   RSI = pointer to the buffer
#   RDX = number of bytes to write
#
# The first syscall is:
#   write(fd, buffer, length)
#
# Then we terminate the process with:
#   exit(0)

.intel_syntax noprefix
.global solve

solve:
    # Preserve the caller's arguments in the registers expected by
    # the Linux write syscall:
    #
    #   RDI = fd
    #   RSI = buffer
    #   RDX = length
    #
    # The original challenge passes these arguments in the same
    # registers, but the next instruction changes RDI, so we first
    # move the values around.

    mov rdx, rsi            # RDX = number of bytes to write
    mov rsi, rdi            # RSI = address of the buffer
    mov rdi, 1              # RDI = stdout file descriptor (1)
    mov rax, 1              # RAX = Linux syscall number for write
    syscall                 # write(stdout, buffer, length)

    # Now terminate the process cleanly.
    # exit() takes the status code in RDI and uses syscall number 60.

    mov rdi, 0              # exit status = 0 (success)
    mov rax, 60             # RAX = Linux syscall number for exit
    syscall                 # exit(0)
