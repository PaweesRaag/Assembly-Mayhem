.intel_syntax noprefix
.global solve
# Sign-extend the signed byte at address RDI into a 64-bit return value.
solve:
    movsx rax, BYTE PTR [rdi]  # Read one byte and propagate its sign bit.
    ret