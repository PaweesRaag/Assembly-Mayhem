.intel_syntax noprefix

# webServer12.s
#
# A minimal x86-64 Linux TCP web server for learning how a browser
# communicates with a server using HTTP.
#
# This version:
#   1. Creates an IPv4 TCP socket.
#   2. Binds it to 127.0.0.1:1337.
#   3. Listens for one incoming connection.
#   4. Accepts one client and reads its HTTP request.
#   5. Prints the received request to the server's terminal.
#   6. Sends a tiny HTTP response containing the body "OK".
#   7. Closes both sockets and exits.
#
# Build:
#   as -o webServer12.o webServer12.s
#   ld -o webServer12 webServer12.o
#
# Run the server in one terminal, then run /challenge/client in another.
#
# This is an intentionally small teaching example, not a production-ready
# HTTP server. It handles one client, assumes one read receives the request,
# and does not check every syscall for errors.

.global _start

.section .data

# Linux x86-64 sockaddr_in structure (16 bytes):
#
# Offset  Size  Field
#   0      2    sin_family  = AF_INET (2)
#   2      2    sin_port    = TCP port in network byte order
#   4      4    sin_addr    = IPv4 address in network byte order
#   8      8    sin_zero    = padding
#
# A bind() call receives a pointer to this structure and its size (16).
address:
    .word 2                  # sin_family: AF_INET means IPv4.
    .word 0x3905             # sin_port: bytes 05 39 = decimal port 1337.
    .long 0x0100007f         # sin_addr: memory bytes 7f 00 00 01 = 127.0.0.1.
    .zero 8                  # sin_zero: eight padding bytes.

# Minimal HTTP response.
#
# HTTP headers end at the blank line represented by \r\n\r\n.
# "OK" is the response body. Because the connection is closed after writing,
# we use HTTP/1.0 and don't need a Content-Length header for this tiny demo.
response:
    .ascii "HTTP/1.0 200 OK\r\n\r\nOK"
response_end:                # Label after the final byte; used to calculate length.

.section .bss

# Reserve writable memory for the incoming HTTP request.
# .bss is zero-initialized memory supplied by the loader.
buffer:
    .skip 4096

.section .text

_start:
    # ------------------------------------------------------------------
    # 1. socket(AF_INET, SOCK_STREAM, 0)
    #
    # Linux x86-64 syscall convention:
    #   rax = syscall number
    #   rdi = argument 1
    #   rsi = argument 2
    #   rdx = argument 3
    # Return value (the new file descriptor, or a negative error) is in rax.
    #
    # socket() creates an endpoint for network communication:
    #   AF_INET      (2) = IPv4
    #   SOCK_STREAM  (1) = reliable byte stream, typically TCP
    #   protocol     (0) = let the OS choose the default for this socket type
    # ------------------------------------------------------------------
    mov rax, 41             # SYS_socket
    mov rdi, 2              # AF_INET
    mov rsi, 1              # SOCK_STREAM
    xor rdx, rdx            # protocol = 0
    syscall
    mov r12, rax            # Preserve the listening socket FD in r12.

    # ------------------------------------------------------------------
    # 2. bind(listen_fd, &address, 16)
    #
    # bind() assigns the socket a local IP address and port. Here that is
    # 127.0.0.1:1337, so the server is reachable through localhost.
    #
    # lea loads the ADDRESS of our data structure into rsi; it does not
    # load the first eight bytes stored at that address.
    # ------------------------------------------------------------------
    mov rax, 49             # SYS_bind
    mov rdi, r12            # Listening socket FD
    lea rsi, [rip + address]# Pointer to sockaddr_in
    mov rdx, 16             # sizeof(sockaddr_in)
    syscall

    # ------------------------------------------------------------------
    # 3. listen(listen_fd, backlog)
    #
    # listen() marks this socket as a passive listener, ready for incoming
    # TCP connections. backlog=1 requests a small pending-connection queue.
    # ------------------------------------------------------------------
    mov rax, 50             # SYS_listen
    mov rdi, r12            # Listening socket FD
    mov rsi, 1              # Connection backlog
    syscall

    # ------------------------------------------------------------------
    # 4. accept(listen_fd, NULL, NULL)
    #
    # accept() waits for a client to connect. With NULL for arguments 2 and 3,
    # we don't ask the kernel to return the client's address.
    #
    # It returns a NEW file descriptor for this client. Keep it separate from
    # r12: the listening FD accepts connections; the client FD carries data.
    # ------------------------------------------------------------------
    mov rax, 43             # SYS_accept
    mov rdi, r12            # Listening socket FD
    xor rsi, rsi            # No peer address output
    xor rdx, rdx            # No peer address length output
    syscall
    mov r13, rax            # Preserve the connected client FD in r13.

    # ------------------------------------------------------------------
    # 5. read(client_fd, buffer, 4096)
    #
    # The browser sends an HTTP request as bytes over the TCP connection.
    # For example, the first line might be:
    #   GET / HTTP/1.1
    #
    # This read obtains up to 4096 bytes. TCP is a byte stream, so a single
    # read is not guaranteed to contain a whole request in a general server.
    # This simple exercise assumes the request arrives in one read.
    # ------------------------------------------------------------------
    xor rax, rax            # SYS_read = 0
    mov rdi, r13            # Read from the client connection
    lea rsi, [rip + buffer] # Destination buffer
    mov rdx, 4096           # Maximum number of bytes to receive
    syscall

    # read() returns:
    #   rax > 0 : number of bytes received
    #   rax = 0 : peer closed the connection (EOF)
    #   rax < 0 : error
    #
    # If nothing useful was received, skip sending the normal response.
    test rax, rax
    jle exit_server

    # Keep the number of request bytes in r14 in case we need it later.
    # r14 is not needed to print the buffer in this minimal version.
    mov r14, rax

    # ------------------------------------------------------------------
    # 6. write(stdout, buffer, bytes_read)
    #
    # Print the exact bytes received so we can inspect the browser's HTTP
    # request in the terminal. write() needs the byte count returned by read;
    # the request buffer is not necessarily a NUL-terminated string.
    # ------------------------------------------------------------------
    mov rdx, r14            # Number of bytes to print
    mov rax, 1              # SYS_write = 1
    mov rdi, 1              # File descriptor 1 = standard output
    lea rsi, [rip + buffer] # Bytes to print
    syscall

    # ------------------------------------------------------------------
    # 7. write(client_fd, response, response_length)
    #
    # Send an HTTP response back to the browser.
    #
    # The first line "HTTP/1.0 200 OK" indicates success.
    # The empty line separates headers from the response body.
    # The body is the two bytes "OK".
    #
    # response_end - response is an assembler-time calculation of the exact
    # byte length; no terminating NUL byte is included in .ascii data.
    # ------------------------------------------------------------------
    mov rax, 1                      # SYS_write
    mov rdi, r13                    # Write to the browser's socket
    lea rsi, [rip + response]       # Pointer to response bytes
    mov rdx, response_end - response# Exact response length
    syscall

exit_server:
    # ------------------------------------------------------------------
    # 8. Close the client socket.
    #
    # Closing tells the OS we're done with this client's connection. Since
    # the response uses HTTP/1.0, the browser can treat connection closure
    # as the end of the response.
    # ------------------------------------------------------------------
    mov rax, 3              # SYS_close
    mov rdi, r13            # Connected client FD
    syscall

    # Close the listening socket too. This version accepts only one client,
    # then shuts the server down; a multi-client server would loop back to
    # accept() instead.
    mov rax, 3              # SYS_close
    mov rdi, r12            # Listening socket FD
    syscall

    # ------------------------------------------------------------------
    # 9. exit(0)
    #
    # Linux exits the process with status 0 to indicate success.
    # ------------------------------------------------------------------
    mov rax, 60             # SYS_exit
    xor rdi, rdi            # Exit status = 0
    syscall
