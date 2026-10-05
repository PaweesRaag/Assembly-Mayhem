.intel_syntax noprefix
# webServer8.s
# Step: accept a client and return a fixed HTTP response.
# This block mirrors the next repeated exercise version.

.global _start

.section .data

address:
    .word 2
    .word 0x5000
    .long 0
    .long 0

response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"

req_buffer:
    .skip 1024

.section .text

_start:
    # socket(AF_INET, SOCK_STREAM, 0)
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov r12, rax

    # bind(socket, &address, 16)
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # listen(socket, 0)
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

    # accept(socket, NULL, NULL)
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r13, rax

    # Receive request bytes.
    mov rax, 0
    mov rdi, r13
    lea rsi, [rip+req_buffer]
    mov rdx, 1024
    syscall

    # Respond with HTTP 200.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip+response]
    mov rdx, 19
    syscall

    # close(client_fd)
    mov rax, 3
    mov rdi, r13
    syscall

    # exit(0)
    mov rdi, 0
    mov rax, 60
    syscall
