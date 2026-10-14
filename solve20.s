.intel_syntax noprefix
.global solve
# Input: RDI = function pointer. Output is whatever the callback returns in RAX.
solve:
    call rdi                   # Invoke function indirectly; saves return address.
    ret                        # Pass control back to caller.