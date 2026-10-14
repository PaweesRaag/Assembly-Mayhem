# Invoke a function pointer passed as the first argument.
# Input: RDI = address of a callable function.
# Output: RAX and other return state are whatever the callee leaves per ABI.
.intel_syntax noprefix
.global solve
solve:
    call rdi                      # Indirect call; pushes return address.
    ret                           # Return to our caller after callee returns.