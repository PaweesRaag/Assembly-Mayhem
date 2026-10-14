.intel_syntax noprefix
.global atoi
.global atoi_digit
# Parse signed decimal digits until the first non-digit; optional leading '-'.
# This educational routine assumes readable NUL-terminated input and no overflow.
atoi:
    push rbx
    xor rbx, rbx
    xor r8, r8                 # R8=1 means negative.
    cmp BYTE PTR [rdi], 0x2D
    jne Loop
    mov r8, 1
    inc rdi
Loop:
    movzx rcx, BYTE PTR [rdi]
    sub rcx, 0x30
    cmp rcx, 9
    ja done                    # Stop if character is not in '0'..'9'.
    imul rbx, 10
    call atoi_digit
    add rbx, rax
    inc rdi
    jmp Loop
done:
    mov rax, rbx
    cmp r8, 1
    jne positive
    neg rax
positive:
    pop rbx
    ret
atoi_digit:
    movzx rax, BYTE PTR [rdi]
    sub rax, 0x30
    ret