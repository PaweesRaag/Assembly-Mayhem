# solve8.s — Call a function pointer and return its result
#
# Purpose:
#   Demonstrates indirect function calls through a register. The caller
#   supplies the address of another function in RDI, and this routine
#   transfers control to that function with CALL.
#
# Input:
#   RDI = address of a callable function.
#
# Output:
#   RAX = value returned by the called function.
#
# Registers:
#   RDI = function pointer supplied by the caller.
#   RAX = return-value register populated by the called function.
#
# Stack / memory:
#   CALL pushes the return address onto the stack. After the called
#   function returns, execution resumes at the instruction immediately
#   following CALL.
#
# Control flow:
#   caller -> solve -> function pointed to by RDI -> solve -> caller
#
# Important detail:
#   The indirect call is performed with "call rdi", so this routine does
#   not need to know the target function's name at assembly time.

.intel_syntax noprefix
.global solve

solve:
    # Transfer control to the function whose address is stored in RDI.
    # CALL also saves the address of the next instruction on the stack.
    call rdi

    # The called function returns its result in RAX. Return that value
    # directly to our caller.
    ret
