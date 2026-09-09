# GDB Cheatsheet — Assembly Mayhem

A practical GDB reference for the x86-64 assembly exercises in **Assembly Mayhem**.

## 1. Start GDB

```bash
gdb ./program
```

Start without showing the introductory banner:

```bash
gdb -q ./program
```

For programs that take command-line arguments:

```bash
gdb --args ./program arg1 arg2
```

Then run with:

```gdb
run
```

## 2. Essential Execution Commands

| Command | Purpose |
|---|---|
| `run` / `r` | Start or restart the program |
| `starti` | Start and stop at the first instruction |
| `continue` / `c` | Continue until the next breakpoint or program stop |
| `stepi` / `si` | Execute one machine instruction |
| `nexti` / `ni` | Step one instruction, stepping over calls |
| `finish` | Run until the current function returns |
| `quit` / `q` | Exit GDB |

For assembly work, `si` is especially useful because it advances exactly one instruction at a time.

## 3. Breakpoints

Set a breakpoint by symbol:

```gdb
break _start
```

Set a breakpoint at a function:

```gdb
break atoi
```

Set a breakpoint at an address:

```gdb
break *0x401000
```

List breakpoints:

```gdb
info breakpoints
```

Delete a breakpoint:

```gdb
delete 1
```

Delete all breakpoints:

```gdb
delete
```

## 4. Inspect the Current Instruction

Show the instruction at the current program counter:

```gdb
x/i $pc
```

Show several instructions starting at the current instruction:

```gdb
x/10i $pc
```

Show instructions around an address:

```gdb
x/10i 0x401000
```

Disassemble a function:

```gdb
disassemble _start
```

## 5. Registers

Display all general-purpose registers:

```gdb
info registers
```

Inspect one register:

```gdb
p $rax
```

Inspect a register in hexadecimal:

```gdb
p/x $rax
```

Useful registers for these exercises:

| Register | Common role |
|---|---|
| `rax` | Return value / syscall number |
| `rbx` | Often used for preserved state |
| `rcx` | Temporary / clobbered by `syscall` |
| `rdx` | Third syscall/function argument / remainder after `div` |
| `rdi` | First argument / syscall argument |
| `rsi` | Second argument / buffer pointer |
| `rsp` | Stack pointer |
| `rbp` | Frame/base pointer when used |
| `r8-r11` | Temporary registers; `r11` is clobbered by `syscall` |
| `r12-r15` | Callee-saved registers; useful for persistent state |
| `rip` / `$pc` | Current instruction address |

Example:

```gdb
p/x $rax
p/x $rdi
p/x $rsp
p/x $pc
```

## 6. Inspect Memory

Examine memory with `x`:

```gdb
x/8gx $rsp
```

Meaning:

- `8` = inspect 8 units
- `g` = giant word (8 bytes)
- `x` = hexadecimal format

Other useful formats:

```gdb
x/16bx $rsp      # 16 bytes in hex
x/16cb $rsp      # 16 bytes as characters
x/8wx  $rsp      # 8 words in hex
x/4gx  $rsp      # 4 quadwords in hex
```

Inspect a string at an address:

```gdb
x/s $rdi
```

This expects a NUL-terminated string.

Inspect a known address containing a string:

```gdb
x/s 0x402000
```

## 7. Stack / `argv` Inspection

At `_start`, the initial stack follows the Linux process startup layout used in these exercises:

```text
[rsp]       = argc
[rsp+8]     = argv[0]
[rsp+16]    = argv[1]
[rsp+24]    = argv[2]
[rsp+32]    = argv[3]
...
```

Inspect the stack:

```gdb
x/8gx $rsp
```

Inspect `argc`:

```gdb
p/d *(long *)$rsp
```

Inspect the pointer stored for `argv[1]`:

```gdb
p/x *(long *)($rsp+16)
```

Then inspect the string that pointer references:

```gdb
x/s *(char **)($rsp+16)
```

Or load the pointer into a register and inspect it:

```gdb
p/x $rdi
x/s $rdi
```

## 8. Examine Specific Bytes

For character comparisons such as:

```asm
cmp byte ptr [rdi], 'p'
```

you can inspect the byte directly:

```gdb
p/x *(unsigned char *)$rdi
p/c *(char *)$rdi
```

Inspect the second byte:

```gdb
p/x *(unsigned char *)($rdi+1)
```

Useful for debugging ASCII parsing:

```gdb
p/d *(unsigned char *)$rdi
p/c *(char *)$rdi
```

## 9. Evaluate Expressions

Print an expression:

```gdb
p $rax + 5
```

Print in hexadecimal:

```gdb
p/x $rax + 5
```

Print in decimal:

```gdb
p/d $rax
```

Print an address:

```gdb
p/x &main
```

The `p/x` form is particularly useful when working with addresses, register contents, bit masks, and hexadecimal values.

## 10. Flags and Comparisons

After instructions such as:

```asm
cmp rax, rbx
```

or:

```asm
cmp byte ptr [rdi], 'p'
```

you can inspect the flags register:

```gdb
p/x $eflags
```

A convenient overview is:

```gdb
info registers eflags
```

When debugging conditional jumps such as `je`, `jne`, `jl`, `jg`, `jb`, and `ja`, stop immediately after the `cmp` to see whether the flags match your expectation.

Important: an instruction placed between `cmp` and the conditional jump can overwrite flags.

## 11. Watch the Program Instruction-by-Instruction

A useful assembly debugging loop is:

```gdb
break _start
run
x/i $pc
info registers
si
x/i $pc
```

For repeated stepping:

```gdb
display/i $pc
si
```

The `display` command automatically prints the selected expression whenever execution stops.

Remove displays with:

```gdb
undisplay
```

## 12. Follow `call` / `ret`

Before entering a function:

```gdb
x/i $pc
si
```

After a `call`, inspect:

```gdb
info registers rsp rip
x/8gx $rsp
```

The `call` instruction pushes a return address onto the stack. `ret` retrieves it from `[rsp]`.

To execute a whole function call without stepping through every instruction inside it:

```gdb
nexti
```

Or run until the current function returns:

```gdb
finish
```

## 13. Inspect Stack Changes

Before a `push`:

```gdb
p/x $rsp
x/4gx $rsp
```

After a `push`:

```gdb
p/x $rsp
x/4gx $rsp
```

Remember:

```text
push value   -> rsp decreases by 8, value stored at [rsp]
pop reg      -> reg gets [rsp], rsp increases by 8
```

Likewise:

```text
sub rsp, N   -> reserve N bytes of stack space
add rsp, N   -> release that space
```

`sub rsp, N` does **not** clear the memory.

## 14. Syscall Debugging

For a Linux `write` syscall:

```text
rax = 1        syscall number
rdi = fd
rsi = buffer
rdx = byte count
```

For `read`:

```text
rax = 0
rdi = fd
rsi = buffer
rdx = byte count
```

For `exit`:

```text
rax = 60
rdi = exit status
```

Before executing `syscall`, inspect:

```gdb
p/d $rax
p/d $rdi
p/x $rsi
p/d $rdx
```

For a string buffer:

```gdb
x/s $rsi
```

For raw bytes:

```gdb
x/32bx $rsi
```

Remember that Linux `syscall` clobbers `rcx` and `r11`, so do not use `r11` for state that must survive a syscall.

## 15. Debugging `atoi`

For a loop that reads bytes from `[rdi]`:

```gdb
break atoi
run
x/s $rdi
x/i $pc
```

At each iteration:

```gdb
p/c *(char *)$rdi
p/d *(unsigned char *)$rdi
p/x $rax
p/x $rbx
si
```

For a digit such as `'7'`, the byte is ASCII `0x37`, and subtracting `0x30` produces numeric value `7`.

To watch a string pointer advance:

```gdb
display/x $rdi
display/c *(char *)$rdi
display/i $pc
```

## 16. Debugging `itoa` / Division

Before a `div rcx`, inspect:

```gdb
p/x $rax
p/x $rdx
p/x $rcx
```

Remember:

```text
div rcx

Dividend = rdx:rax
Quotient = rax
Remainder = rdx
```

For decimal conversion, clearing `rdx` before `div` is essential when using a plain positive integer dividend:

```asm
xor rdx, rdx
div rcx
```

## 17. Useful One-Liners

Show the current instruction:

```gdb
x/i $pc
```

Show the next 10 instructions:

```gdb
x/10i $pc
```

Show RAX in hex:

```gdb
p/x $rax
```

Show the stack:

```gdb
x/16gx $rsp
```

Show a string:

```gdb
x/s $rdi
```

Show raw bytes:

```gdb
x/16bx $rdi
```

Run one instruction:

```gdb
si
```

Continue:

```gdb
c
```

Restart:

```gdb
run
```

## 18. A Practical Debugging Template

For these Assembly Mayhem exercises, this sequence covers most problems:

```bash
gdb -q ./program
```

```gdb
break _start
run
x/i $pc
info registers
x/8gx $rsp
```

Then step:

```gdb
display/i $pc
si
```

When working with pointers:

```gdb
p/x $rdi
x/s $rdi
x/16bx $rdi
```

When working with the stack:

```gdb
p/x $rsp
x/16gx $rsp
```

When debugging a comparison:

```gdb
x/i $pc
si
p/x $eflags
x/i $pc
```

When debugging a syscall:

```gdb
p/d $rax
p/d $rdi
p/x $rsi
p/d $rdx
x/16bx $rsi
```

## 19. Quick Reference

```text
Execution
---------
r / run          start program
c / continue     continue
si / stepi       one instruction
ni / nexti       one instruction, step over call
finish           run until current function returns

Breakpoints
-----------
b _start         breakpoint at symbol
b *ADDR          breakpoint at address
info breakpoints list breakpoints
delete N         delete breakpoint N

Instructions
------------
x/i $pc          current instruction
x/10i $pc        next 10 instructions
disassemble f    disassemble function f

Registers
---------
info registers   all registers
p/x $rax         register in hex
p/d $rax         register in decimal

Memory
------
x/8gx $rsp       8 quadwords, hex
x/16bx ADDR      16 bytes, hex
x/s ADDR         NUL-terminated string
x/i ADDR         instruction at address

Stack / argv
------------
[rsp]            argc
[rsp+8]          argv[0]
[rsp+16]         argv[1]
[rsp+24]         argv[2]
[rsp+32]         argv[3]

Useful registers
----------------
$pc / $rip       instruction pointer
$rsp             stack pointer
$rdi             first argument / syscall argument
$rsi             second argument / buffer
$rdx             third argument / byte count
$rax             return value / syscall number
```
## Additional Resources

- [pwn.college Assembly Crash Course / accompanying video](https://www.youtube.com/watch?v=r185fCzdw8Y&time_continue=114&source_ve_path=NzY3NTg&embeds_referring_euri=https%3A%2F%2Fpwn.college%2F) — Video companion for the low-level assembly material used alongside these exercises.
