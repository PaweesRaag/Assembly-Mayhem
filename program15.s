.intel_syntax noprefix
.global _start

_start:
    # Build the string "/flag" directly in the stack buffer.
    mov BYTE PTR [rsp], '/'
    mov BYTE PTR [rsp+1], 'f'
    mov BYTE PTR [rsp+2], 'l'
    mov BYTE PTR [rsp+3], 'a'
    mov BYTE PTR [rsp+4], 'g'
    mov BYTE PTR [rsp+5], 0

    # Open /flag for reading.
    mov rdi, rsp
    mov rsi, 0
    mov rax, 2
    syscall

    # Read up to 128 bytes from the file.
    mov rdi, rax
    mov rsi, rsp
    mov rdx, 128
    mov rax, 0
    syscall

    # Write the bytes read to stdout.
    mov rdi, 1
    mov rsi, rsp
    mov rdx, rax
    mov rax, 1
    syscall

    # Exit with status 42.
    mov rax, 60
    mov rdi, 42
    syscall
