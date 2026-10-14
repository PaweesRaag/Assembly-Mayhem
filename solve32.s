.intel_syntax noprefix
.global solve
# Temporarily load callee-saved registers with 0x1337 around a callback.
# The original values are saved and restored to obey the calling convention.
solve:
    push rbx
    push rbp
    push r12
    push r13
    push r14
    push r15
    mov rbx, 0x1337
    mov rbp, 0x1337
    mov r12, 0x1337
    mov r13, 0x1337
    mov r14, 0x1337
    mov r15, 0x1337
    call rdi
    pop r15
    pop r14
    pop r13
    pop r12
    pop rbp
    pop rbx
    ret