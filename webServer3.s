# webServer3.s
# GET + POST HTTP request handling with forked clients.
# This is the larger dual-method server from the pasted program list.

.intel_syntax noprefix
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
    # Create the listening IPv4/TCP socket.
    mov rax, 41
    mov rdi, 2
    mov rsi, 1
    mov rdx, 0
    syscall
    mov r12, rax

    # Bind it to the exercise's address structure.
    mov rax, 49
    mov rdi, r12
    lea rsi, [rip + address]
    mov rdx, 16
    syscall

    # Mark the socket as listening.
    mov rax, 50
    mov rdi, r12
    mov rsi, 0
    syscall

accept_loop:
    # Wait for one incoming connection.
    mov rax, 43
    mov rdi, r12
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r13, rax

    # Fork so the parent can immediately return to accept().
    mov rax, 57
    syscall
    cmp rax, 0
    je child

parent:
    # Parent releases its copy of the client FD.
    mov rax, 3
    mov rdi, r13
    syscall
    jmp accept_loop

child:
    # Child releases its copy of the listening FD.
    mov rax, 3
    mov rdi, r12
    syscall

    # Read the HTTP request.
    mov rax, 0
    mov rdi, r13
    lea rsi, [rip + req_buffer]
    mov rdx, 1024
    syscall
    mov r14, rax
    lea rbx, [rip + req_buffer]

    # ------------------------------
    # GET method recognition
    # ------------------------------
    cmp byte ptr [rbx], 'G'
    jne check_post
    cmp byte ptr [rbx + 1], 'E'
    jne invalid
    cmp byte ptr [rbx + 2], 'T'
    jne invalid
    cmp byte ptr [rbx + 3], ' '
    jne invalid

    # GET path begins after "GET ".
    lea rsi, [rbx + 4]

    # r8 = request type; zero means GET.
    mov r8, 0
    jmp find_path_end

check_post:
    # ------------------------------
    # POST method recognition
    # ------------------------------
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

    # POST path begins after "POST ".
    lea rsi, [rbx + 5]

    # r8 = request type; one means POST.
    mov r8, 1

find_path_end:
    # Copy path pointer to a scanning register.
    mov r9, rsi

path_scan:
    # Walk until the space before HTTP/1.1.
    cmp byte ptr [r9], ' '
    je path_found
    inc r9
    jmp path_scan

path_found:
    # NUL-terminate the path in-place.
    mov byte ptr [r9], 0

    # Dispatch to GET or POST based on r8.
    cmp r8, 1
    je post_op
    jmp get_op

# ============================================================
# GET HANDLER
# ============================================================
get_op:
    # open(path, O_RDONLY, 0)
    mov rax, 2
    lea rdi, [rbx + 4]
    mov rsi, 0
    mov rdx, 0
    syscall
    mov r14, rax

    # read(file_fd, file_buffer, 4096)
    mov rax, 0
    mov rdi, r14
    lea rsi, [rip + file_buffer]
    mov rdx, 4096
    syscall
    mov r15, rax

    # close(file_fd)
    mov rax, 3
    mov rdi, r14
    syscall

    # Send the HTTP response header.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + response]
    mov rdx, 19
    syscall

    # Send the file contents.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + file_buffer]
    mov rdx, r15
    syscall

    # Close client socket.
    mov rax, 3
    mov rdi, r13
    syscall
    jmp exit

# ============================================================
# POST HANDLER
# ============================================================
post_op:
    # Search for the CRLF CRLF header/body boundary.
    mov rdi, 0

find_body:
    # Check all four bytes of the delimiter.
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
    # The body begins four bytes after the delimiter.
    lea r8, [rbx + rdi + 4]

    # Compute body length from total request length.
    mov r15, r14
    sub r15, rdi
    sub r15, 4

    # Open/create the POST destination.
    mov rax, 2
    lea rdi, [rbx + 5]
    mov rsi, 65
    mov rdx, 0777
    syscall
    mov r14, rax

    # Persist the request body.
    mov rax, 1
    mov rdi, r14
    mov rsi, r8
    mov rdx, r15
    syscall

    # Close output file.
    mov rax, 3
    mov rdi, r14
    syscall

    # Return a minimal HTTP success response.
    mov rax, 1
    mov rdi, r13
    lea rsi, [rip + response]
    mov rdx, 19
    syscall

    # Close client connection.
    mov rax, 3
    mov rdi, r13
    syscall
    jmp exit

exit:
    # Successful child termination.
    mov rax, 60
    mov rdi, 0
    syscall

invalid:
    # Invalid request termination.
    mov rax, 60
    mov rdi, 1
    syscall
