.intel_syntax noprefix
.global _start
.section .text

# ------------------------------------------------------------
# webServer1.s
# Minimal first step: create an IPv4/TCP socket.
# This program demonstrates the socket() system call only.
# ------------------------------------------------------------

_start:
    # socket(AF_INET, SOCK_STREAM, IPPROTO_IP)
    # RAX = 41  -> socket syscall
    # RDI = 2   -> AF_INET
    # RSI = 1   -> SOCK_STREAM
    # RDX = 0   -> protocol selected by the kernel
mov rax, 41
mov rdi, 2
mov rsi, 1
mov rdx, 0
syscall

# Return success so the process terminates cleanly.
mov rdi, 0
mov rax, 60
syscall
