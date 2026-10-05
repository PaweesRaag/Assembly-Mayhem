.intel_syntax noprefix
# webServer6.s
# Step: create, bind, listen, and accept one client connection.

.global _start

.section .data

address:
    .word 2
    .word 0x5000
    .long 0
    .long 0

.section .text

_start:
    # socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall

    # R12 holds the listening socket descriptor.
    mov r12, rax

    # bind(listening_fd, &address, 16)
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # listen(listening_fd, 0)
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

    # accept(listening_fd, NULL, NULL)
    # A successful return value is the connected client FD.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall

    # The next step in the progression would use this returned FD.
    # The original exercise exits immediately after accept().
    mov rdi, 0
    mov rax, 60
    syscall
