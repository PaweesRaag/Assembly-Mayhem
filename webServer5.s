.intel_syntax noprefix
# webServer5.s
# Step: socket -> bind -> listen.

.global _start
.section .data

address:
    # sockaddr data consumed by bind().
    .word 2
    .word 0x5000
    .long 0
    .long 0

.section .text

_start:
    # Create an IPv4 TCP socket.
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall

    # Save the listening socket FD.
    mov r12, rax

    # Bind the socket to the exercise address.
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # Put the socket into listening state.
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

    # End the process successfully.
    mov rdi, 0
    mov rax, 60
    syscall
