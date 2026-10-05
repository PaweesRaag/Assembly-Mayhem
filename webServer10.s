.intel_syntax noprefix
# webServer10.s
# Step: persistent GET file server; accept() repeats in a loop.

.global _start

.section .data

address:
    .word 2
    .word 0x5000
    .long 0
    .long 0

file_buffer:
    .skip 4096

req_buffer:
    .skip 1024

response:
    .ascii "HTTP/1.0 200 OK\r\n\r\n"

.section .text

_start:
    # socket()
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov r12, rax

    # bind()
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip+address]
    mov rdx, 16
    syscall

    # listen()
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

accept_loop:
    # Wait for the next client.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r13, rax

    # Read request.
    mov rax, 0
    mov rdi, r13
    lea rsi, [rip+req_buffer]
    mov rdx, 1024
    syscall

    lea rbx, [rip+req_buffer]

    # Require GET.
    cmp BYTE PTR[rbx], 'G'
    jne invalid
    cmp BYTE PTR[rbx+1], 'E'
    jne invalid
    cmp BYTE PTR[rbx+2], 'T'
    jne invalid
    cmp BYTE PTR[rbx+3], ' '
    jne invalid

    # Locate end of path and insert NUL.
    lea rsi, [rbx+4]

null:
    cmp BYTE PTR[rsi], ' '
    je null_found
    inc rsi
    jmp null

null_found:
    mov BYTE PTR[rsi], 0

    # Open requested file read-only.
    mov rax, 2
    lea rdi, [rbx+4]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r14, rax

    # Read file contents.
    mov rax, 0
    mov rdi, r14
    lea rsi, [rip+file_buffer]
    mov rdx, 4096
    syscall
    mov r15, rax

    # Close the file.
    mov rax, 3
    mov rdi, r14
    syscall

    # Send HTTP response.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + response]
    mov rdx, 19
    syscall

    # Send file contents.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip+file_buffer]
    mov rdx, r15
    syscall

    # Close this client.
    mov rax, 3
    mov rdi, r13
    syscall

    # Continue accepting clients forever.
    jmp accept_loop

invalid:
    # Malformed request exits with status 1.
    mov rax, 60
    mov rdi, 1
    syscall

    # Unreachable in normal invalid flow; retained from the source progression.
    mov rdi, 0
    mov rax, 60
    syscall
