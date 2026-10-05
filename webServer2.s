# webServer2.s
# Socket + bind + listen + accept + fork.
# Comments explain the register/data flow while preserving the exercise's syscall sequence.

.intel_syntax noprefix
.global _start

.section .data

address:
    # sockaddr_in-style layout used by the exercise.
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
    # socket(AF_INET, SOCK_STREAM, IPPROTO_IP)
    # RAX = syscall number 41
    # RDI = AF_INET (2)
    # RSI = SOCK_STREAM (1)
    # RDX = protocol 0
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall

    # Keep the listening socket FD in R12 across later syscalls.
    mov r12, rax

    # bind(listening_fd, &address, 16)
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip + address]
    mov rdx, 16
    syscall

    # listen(listening_fd, backlog=0)
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

accept_loop:
    # accept() blocks until a client connects.
    # Its return value is the new client socket FD.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r13, rax

    # fork() duplicates the process.
    # Child sees RAX=0; parent sees child's PID.
    mov rax, 57
    syscall
    cmp rax, 0
    je child

parent:
    # Parent closes its copy of the connected client FD.
    mov rax, 3
    mov rdi, r13
    syscall

    # Parent returns to accepting clients.
    jmp accept_loop

child:
    # Child closes its inherited listening FD.
    mov rax, 3
    mov rdi, r12
    syscall

    # Read an HTTP request from the connected client.
    mov rax, 0
    mov rdi, r13
    lea rsi, [rip + req_buffer]
    mov rdx, 1024
    syscall

    # Preserve request length and buffer base.
    mov r14, rax
    lea rbx, [rip + req_buffer]

    # Check for the POST method prefix.
    cmp byte ptr [rbx], 'P'
    jne invalid
    cmp byte ptr [rbx + 1], 'O'
    jne invalid
    cmp byte ptr [rbx + 2], 'S'
    jne invalid
    cmp byte ptr [rbx + 3], 'T'
    jne invalid
    cmp byte ptr [rbx + 4], ' '
    jne invalid

    # Path starts at request + 5 bytes: "POST ".
    lea r8, [rbx + 5]

find_path_end:
    # Find the space that terminates the request path.
    cmp byte ptr [r8], ' '
    je path_found
    inc r8
    jmp find_path_end

path_found:
    # Replace the path/version separator with NUL.
    # This lets the path be passed directly to open().
    mov byte ptr [r8], 0

    # Scan for CRLF CRLF, the HTTP header terminator.
    mov rdi, 0

find_body:
    cmp byte ptr [rbx + rdi], 13
    jne next_byte
    cmp byte ptr [rbx + rdi + 1], 10
    jne next_byte
    cmp byte ptr [rbx + rdi + 2], 13
    jne next_byte
    cmp byte ptr [rbx + rdi + 3], 10
    je body_found

next_byte:
    inc rdi
    jmp find_body

body_found:
    # Body begins immediately after the four-byte terminator.
    lea r8, [rbx + rdi + 4]

    # body_length = total_request_bytes - header_offset - 4
    mov r15, r14
    sub r15, rdi
    sub r15, 4

    # open(path, O_WRONLY|O_CREAT, 0777)
    mov rax, 2
    lea rdi, [rbx + 5]
    mov rsi, 65
    mov rdx, 0777
    syscall
    mov r14, rax

    # write(file_fd, body, body_length)
    mov rax, 1
    mov rdi, r14
    mov rsi, r8
    mov rdx, r15
    syscall

    # close(file_fd)
    mov rax, 3
    mov rdi, r14
    syscall

    # Send HTTP/1.0 200 OK.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + response]
    mov rdx, 19
    syscall

    # Close the connected socket.
    mov rax, 3
    mov rdi, r13
    syscall

    # exit(0)
    mov rax, 60
    mov rdi, 0
    syscall

invalid:
    # Malformed request: terminate with status 1.
    mov rax, 60
    mov rdi, 1
    syscall
