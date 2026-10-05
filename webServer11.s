.intel_syntax noprefix
# webServer11.s
# Step: fork each accepted client, allowing the parent to continue accepting.

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
    # socket(AF_INET, SOCK_STREAM, 0)
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
    # Accept a connected client.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r13, rax

    # fork() splits execution into parent and child.
    mov rax, 57
    syscall

    # Child receives zero from fork().
    cmp rax, 0
    je child

parent:
    # Parent closes its client copy.
    mov rax, 3
    mov rdi, r13
    syscall

    # Parent immediately returns to accept().
    jmp accept_loop

child:
    # Child closes the inherited listening FD.
    mov rax, 3
    mov rdi, r12
    syscall

    # Read request from client.
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

    # Path starts after "GET ".
    lea rsi, [rbx+4]

null:
    # Scan to the space after the path.
    cmp BYTE PTR[rsi], ' '
    je null_found
    inc rsi
    jmp null

null_found:
    # NUL-terminate the filename.
    mov BYTE PTR[rsi], 0

    # open(filename, O_RDONLY, 0)
    mov rax, 2
    lea rdi, [rbx+4]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r14, rax

    # read(file_fd, file_buffer, 4096)
    mov rax, 0
    mov rdi, r14
    lea rsi, [rip+file_buffer]
    mov rdx, 4096
    syscall
    mov r15, rax

    # close(file_fd)
    mov rax, 3
    mov rdi, r14
    syscall

    # Send HTTP response headers.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + response]
    mov rdx, 19
    syscall

    # Send file content.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip+file_buffer]
    mov rdx, r15
    syscall

    # Close client.
    mov rax, 3
    mov rdi, r13
    syscall

    # Child exits after servicing one request.
    mov rdi, 0
    mov rax, 60
    syscall

invalid:
    # Invalid request -> exit status 1.
    mov rax, 60
    mov rdi, 1
    syscall
