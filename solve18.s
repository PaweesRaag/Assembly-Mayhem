# Count distinct byte values in a fixed-length input buffer.
# Input: RDI = buffer, RSI = byte length. Output: RAX = number of distinct
# byte values observed. A 256-byte stack table records whether each value
# has appeared. Caller must provide a valid readable buffer of RSI bytes.
.intel_syntax noprefix
.global solve
solve:
    sub rsp, 256                   # Reserve one byte for each possible byte value.
    xor ecx, ecx
clear_loop:
    mov BYTE PTR [rsp+rcx], 0      # Mark every value as not seen.
    inc rcx
    cmp rcx, 256
    jne clear_loop
count:
    test rsi, rsi                  # Stop when no input bytes remain.
    jz count_done
    movzx rcx, BYTE PTR [rdi]      # Read next input byte as an index 0..255.
    mov BYTE PTR [rsp+rcx], 1      # Mark this byte value as present.
    inc rdi
    dec rsi
    jmp count
count_done:
    xor rcx, rcx                   # Index through the seen table.
    xor eax, eax                   # RAX counts distinct values.
check:
    cmp BYTE PTR [rsp+rcx], 1
    jne not_present
    inc rax
not_present:
    inc rcx
    cmp rcx, 256
    jne check
    add rsp, 256                   # Restore stack pointer before returning.
    ret