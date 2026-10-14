.intel_syntax noprefix
.global solve
# Calls callback in RDI, preserves selected caller-saved registers around it,
# then calls the function pointer in RSI. This is an ABI experiment.
solve:
    push rax
    push rcx
    push rdx
    push rsi
    push rdi
    push r8
    push r9
    push r10
    push r11
    call rdi                   # First callback.
    pop r11
    pop r10
    pop r9
    pop r8
    pop rdi
    pop rsi
    pop rdx
    pop rcx
    pop rax
    call rsi                   # Second callback, using restored RSI.
    ret