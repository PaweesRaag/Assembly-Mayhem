.intel_syntax noprefix
.global atoi_digit
.global atoi
# atoi_digit converts the character at [RDI] into a digit in RAX.
atoi_digit:
    movzx rax, BYTE PTR [rdi]
    sub rax, 0x30
    ret
# Parse exactly two decimal characters at RDI; return tens*10 + ones in RAX.
atoi:
    push rbx                   # RBX is callee-saved.
    call atoi_digit            # Convert tens digit.
    mov rbx, rax
    inc rdi                    # Point at ones digit.
    call atoi_digit
    imul rbx, 10               # Scale tens place.
    add rax, rbx               # Add ones digit.
    pop rbx
    ret