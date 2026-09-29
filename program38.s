# program38.s — raw Linux x86-64 write and exit syscalls
#
# Purpose:
#   A minimal example of interacting with Linux directly through the
#   syscall instruction. The function takes three values in registers
#   and rearranges them into the register layout required by write(2).
#
# Input convention:
#   RDI = address of the buffer to print
#   RSI = number of bytes to print
#   RDX = unused by the caller here
#
# Linux x86-64 syscall convention:
#   RAX = syscall number
#   RDI = arg1
#   RSI = arg2
#   RDX = arg3
#
# write(1, buffer, length):
#   RAX = 1   -> write
#   RDI = 1   -> stdout
#   RSI = buffer
#   RDX = length
#
# exit(0):
#   RAX = 60  -> exit
#   RDI = 0   -> success status

.intel_syntax noprefix
.global solve

solve:
    # The challenge's function arguments are arranged differently from
    # the Linux write syscall. Move them into the correct syscall slots.
    mov rdx, rsi            # RDX = number of bytes to write
    mov rsi, rdi            # RSI = pointer to the buffer
    mov rdi, 1              # RDI = stdout file descriptor
    mov rax, 1              # RAX = syscall number for write
    syscall                 # write(1, buffer, length)

    # Terminate the process after the write.
    mov rdi, 0              # exit status = 0
    mov rax, 60             # RAX = syscall number for exit
    syscall                 # exit(0)
