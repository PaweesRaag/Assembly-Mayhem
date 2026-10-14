.intel_syntax noprefix
.global atoi
.global atoi_digit
# Parse a NUL-terminated signed decimal string; optional leading '-' supported.
# Assumes valid digits and does not check overflow.
atoi:
    push rbx
    xor rbx, rbx
    cmp BYTE PTR [rdi], 0x2D   # Leading minus?
    je negative
positive_loop:
    cmp BYTE PTR [rdi], 0
    je positive_end
    imul rbx, 10
    call atoi_digit
    add rbx, rax
    inc rdi
    jmp positive_loop
negative:
    inc rdi                    # Skip '-'.
negative_loop:
    cmp BYTE PTR [rdi], 0
    je negative_end
    imul rbx, 10
    call atoi_digit
    add rbx, rax
    inc rdi
    jmp negative_loop
negative_end:
    mov rax, rbx
    neg rax
    pop rbx
    ret
positive_end:
    mov rax, rbx
    pop rbx
    ret
atoi_digit:
    movzx rax, BYTE PTR [rdi]
    sub rax, 0x30
    ret