.intel_syntax noprefix
# webServer7.s
# Step: accept one client, read its request, and send a fixed HTTP response.

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
    # Create the listening socket.
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall

    # Preserve listening FD.
    mov r12, rax

    # Bind.
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # Listen.
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

    # Accept a client.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall

    # Preserve the connected client FD.
    mov r13, rax

    # Read a request from the client.
    mov rax, 0
    mov rdi, r13
    lea rsi, [rip+req_buffer]
    mov rdx, 1024
    syscall

    # Send a minimal HTTP/1.0 response.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip+response]
    mov rdx, 19
    syscall

    # Close client connection.
    mov rax, 3
    mov rdi, r13
    syscall

    # Exit successfully.
    mov rdi, 0
    mov rax, 60
    syscall
