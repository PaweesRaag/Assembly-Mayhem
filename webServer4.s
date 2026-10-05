.intel_syntax noprefix
# webServer4.s
# Step: create a socket, save its FD, and bind it to the supplied address.

.global _start
.section .data

address:
    # IPv4 family, exercise port value, and zero address.
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

    # Preserve socket FD in R12.
    mov r12, rax

    # bind(socket_fd, &address, 16)
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # exit(0)
    mov rdi, 0
    mov rax, 60
    syscall
