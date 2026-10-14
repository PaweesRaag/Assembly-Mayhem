.intel_syntax noprefix
.global solve
# Input: RDI = callback address. Calls callback with 1337 as its first argument.
solve:
    mov rax, rdi               # Preserve callback address before replacing RDI.
    mov rdi, 1337              # Set callback's first argument.
    call rax                   # Invoke callback.
    ret