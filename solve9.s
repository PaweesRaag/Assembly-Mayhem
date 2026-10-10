# solve9.s — Write 64 bytes from a stack-relative address to standard output
#
# Purpose:
#   Demonstrates the Linux x86-64 write system call and how LEA can form an
#   address relative to RSP. This is a low-level example of passing a buffer
#   pointer and byte count directly to the kernel.
#
# Inputs / assumptions:
#   The routine assumes that the memory beginning at [RSP + 0x40] contains
#   at least 64 readable bytes that are appropriate to write.
#   No explicit function argument is used as the buffer pointer.
#
# System call interface on Linux x86-64:
#   RAX = syscall number
#   RDI = argument 1
#   RSI = argument 2
#   RDX = argument 3
#
# For write(fd, buffer, count):
#   RAX = 1       (SYS_write)
#   RDI = 1       (standard output)
#   RSI = buffer  (address of first byte)
#   RDX = count   (number of bytes)
#
# Registers:
#   RSP = current stack pointer; used as the base for the buffer address.
#   RSI = address passed as the write buffer.
#   RDI = file descriptor 1 (stdout).
#   RDX = 64-byte write length.
#   RAX = system-call number for write.
#
# Memory:
#   LEA computes RSP + 0x40 as an address; it does not read memory itself.
#   The kernel's write operation then attempts to read 64 bytes beginning
#   at that address.
#
# Control flow:
#   Set up the buffer pointer and write arguments, invoke SYSCALL, then
#   return to the caller. The return value from write (bytes written or a
#   negative error code) is left in RAX until RET transfers control back.
#
# Important caveat:
#   A stack-relative address is valid only if the caller/challenge has placed
#   the intended data there and the memory is readable. This routine does not
#   check the syscall result or retry a short write.

.intel_syntax noprefix
.global solve

solve:
    # Form the address 64 bytes above the current stack pointer.
    # LEA calculates an address; it does not dereference that address.
    lea rsi, [rsp+0x40]

    # First write argument: file descriptor 1 means standard output.
    mov rdi, 1

    # Third write argument: request a write of exactly 64 bytes.
    mov rdx, 64

    # SYS_write is syscall number 1 on Linux x86-64.
    mov rax, 1

    # Enter the kernel: write(stdout, [RSP+0x40], 64).
    syscall

    # Return to the caller. RAX contains the syscall result.
    ret
