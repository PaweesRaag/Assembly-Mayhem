# Reserve 256 stack bytes, zero them, then restore the stack pointer.
# This demonstrates a byte-wise loop over a stack buffer.
.intel_syntax noprefix
.global solve
solve:
    sub rsp, 256                   # Allocate 256 bytes below current RSP.
    xor rcx, rcx                   # RCX = index 0.
loop:
    mov BYTE PTR [rsp+rcx], 0      # Clear the indexed byte.
    inc rcx                        # Advance index.
    cmp rcx, 256                   # Have all 256 bytes been cleared?
    jne loop
    add rsp, 256                   # Release the local buffer.
    ret