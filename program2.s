.intel_syntax noprefix
.global _start

_start:
    ; Load the Linux exit syscall number.
    ; syscall 60 = exit(int status)
    mov rax, 60

    ; Load the value stored at memory address 0x123400
    ; into RDI. For exit(), RDI is the status code.
    mov rdi, [0x123400]

    ; Terminate the process with the value from memory
    ; as its exit status.
    syscall
