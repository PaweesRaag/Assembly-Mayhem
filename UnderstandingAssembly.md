# Understanding x86-64 Assembly — From Individual Instructions to Whole-Program Reading

> Learning notes from a line-by-line reverse-engineering session.
>
> Goal: move from understanding individual assembly instructions to understanding an entire compiled program by tracking registers, stack variables, function calls, control flow, and data flow.

---

## 1. The main problem: individual instructions vs. the whole program

A beginner may understand:

```asm
mov rax, rbx
add rax, 1
cmp rax, rbx
```

but still struggle to read a whole function.

The key is to stop reading assembly as a flat sequence of instructions and instead ask:

> **What is the program trying to accomplish at this point?**

For example:

```asm
mov rax, [rbp-0x10]
mov rsi, rax
lea rax, [rip+...]
mov rdi, rax
call printf
```

Instead of thinking:

```text
mov → mov → lea → mov → call
```

think:

> Load a local value → place it in the second function-argument register → locate the format string → place it in the first function-argument register → call `printf`.

That is the transition from **instruction-level understanding** to **program-level understanding**.

---

# 2. x86-64 Linux calling convention

This program is x86-64 Linux code using the System V AMD64 calling convention.

For function arguments:

```text
RDI → argument #1
RSI → argument #2
RDX → argument #3
RCX → argument #4
R8  → argument #5
R9  → argument #6
```

Important general-purpose registers for reading this program:

```text
RAX → return value / scratch
RBP → stack-frame base
RSP → stack pointer
RIP → instruction pointer
```

So if you see:

```asm
mov rdi, rax
call puts
```

you should immediately think:

> `rax` contains the first argument to `puts`.

---

# 3. Function prologue

The beginning of `main`:

```asm
endbr64
push rbp
mov rbp,rsp
sub rsp,0x40
```

## `endbr64`

This is associated with Intel Control-flow Enforcement Technology (CET), specifically Indirect Branch Tracking.

For ordinary reverse-engineering logic, treat it as compiler/security boilerplate unless you specifically need to analyze CET.

## `push rbp`

Conceptually:

```text
RSP = RSP - 8
[RSP] = old RBP
```

The old frame pointer is saved on the stack.

## `mov rbp,rsp`

Now:

```text
RBP = RSP
```

This establishes the stack-frame base.

The compiler can now refer to local variables with offsets such as:

```text
[rbp-0x10]
[rbp-0x18]
[rbp-0x1c]
```

## `sub rsp,0x40`

```text
0x40 = 64 bytes
```

The program reserves 64 bytes of stack space for the function.

A rough picture:

```text
HIGH ADDRESS
    │
    │ saved RBP
    │ local variables
    │ ...
    ▼
   RSP
LOW ADDRESS
```

---

# 4. `argc`, `argv`, and `envp` are saved onto the stack

The program contains:

```asm
mov DWORD PTR [rbp-0x24],edi
mov QWORD PTR [rbp-0x30],rsi
mov QWORD PTR [rbp-0x38],rdx
```

For a normal C-style `main`:

```c
int main(int argc, char **argv, char **envp)
```

Therefore:

```text
EDI → argc
RSI → argv
RDX → envp
```

and the stack frame stores them as:

```text
[rbp-0x24] = argc
[rbp-0x30] = argv
[rbp-0x38] = envp
```

---

# 5. Stack canary setup

The program has:

```asm
mov rax,QWORD PTR fs:0x28
mov QWORD PTR [rbp-0x8],rax
xor eax,eax
```

## `mov rax,QWORD PTR fs:0x28`

Literally:

> Read 8 bytes from memory at `FS:0x28` and put them into `RAX`.

A useful conceptual model is:

```c
rax = *(uint64_t *)(FS_base + 0x28);
```

On the Linux x86-64 runtime used here, this value is the stack guard / stack canary.

`FS` is an x86-64 segment register commonly used for thread-local storage (TLS).

So mentally:

```text
FS
 ↓
thread-local storage
 ↓
offset 0x28
 ↓
stack canary value
```

## `mov [rbp-0x8],rax`

The canary is copied into this function's stack frame:

```text
[rbp-0x8] = canary
```

## `xor eax,eax`

This sets:

```text
EAX = 0
RAX = 0
```

because writing to a 32-bit register zero-extends into the corresponding 64-bit register.

---

# 6. Why `RIP` appears in the disassembly

This was one of the major conceptual sticking points.

`RIP` is the **instruction pointer**. It identifies the current execution position in the instruction stream.

However, when you see:

```asm
lea rax,[rip+0x6ba]
```

it does **not** mean "read the next instruction."

Instead, `RIP` is used as a **reference point for calculating another address**.

Conceptually:

```c
rax = address_relative_to_rip;
```

For example, if a simplified instruction uses:

```asm
lea rax,[rip+0x100]
```

and the next instruction is conceptually at `0x1000`, the target address is:

```text
0x1000 + 0x100 = 0x1100
```

The program may have static data such as strings nearby:

```text
CODE
0x1000    lea rax,[rip+0x100]
0x1007    mov rdi,rax
0x100A    call puts

DATA
0x1100    "Hello world!"
```

The code is using RIP-relative addressing to find the string.

## Why this is useful

Absolute addresses can change when programs are relocated, including under ASLR / position-independent execution. A relative distance from the code to nearby data can remain the same.

Thus:

```asm
lea rax,[rip+offset]
```

is often mentally translated as:

> Get the address of some nearby static data (often a string or format string).

## Important distinction: `LEA` vs `MOV`

```asm
lea rax,[rip+0x6ba]
```

means roughly:

```c
rax = RIP + 0x6ba;
```

It calculates the **address**.

Whereas:

```asm
mov rax,[rip+0x6ba]
```

means conceptually:

```c
rax = *(RIP + 0x6ba);
```

It accesses the **contents at that address**.

So:

```text
LEA → calculate address
MOV with [] → access memory at that address
```

## Small technical detail

For x86-64 RIP-relative addressing, the displacement is based on the RIP of the **next instruction**.

That is why a line like:

```asm
0x5743b4c33b13: lea rax,[rip+0x6ba]
0x5743b4c33b1a: mov rdi,rax
```

can resolve to:

```text
0x5743b4c33b1a + 0x6ba = 0x5743b4c341d4
```

The disassembler reports that resolved target address.

---

# 7. `setvbuf` calls

The program has a sequence like:

```asm
mov rax,QWORD PTR [rip+...]
mov ecx,0x0
mov edx,0x2
mov esi,0x0
mov rdi,rax
call setvbuf
```

The first sequence loads `stdin`, then prepares arguments:

```text
RDI = stdin
RSI = 0
RDX = 2
RCX = 0
```

Conceptually:

```c
setvbuf(stdin, 0, 2, 0);
```

A very similar block is used for `stdout`.

The useful reverse-engineering pattern is:

```asm
mov rdi, ...
mov rsi, ...
mov rdx, ...
mov rcx, ...
call function
```

→ prepare function arguments according to the calling convention, then call the function.

---

# 8. The large sequence of `puts`

The program repeatedly does:

```asm
lea rax,[rip+...]
mov rdi,rax
call puts
```

The important idea is not to manually decode every address.

This pattern means approximately:

```c
puts("...");
```

The `lea` finds the address of a static string using RIP-relative addressing. `mov rdi,rax` places that address into the first argument register. `call puts` prints the string.

The program has many such blocks because it prints a lot of challenge/menu text.

When reverse engineering, repetitive patterns should be collapsed mentally into one conceptual operation instead of treated as unique logic.

---

# 9. `putchar(10)`

The program includes:

```asm
mov edi,0xa
call putchar
```

`0xa` is hexadecimal 10 decimal, and ASCII 10 is newline (`'\n'`).

So this is effectively:

```c
putchar('\n');
```

---

# 10. `int3`

The disassembly contains:

```asm
int3
nop
```

`int3` is the x86 breakpoint instruction and generates a breakpoint trap.

It may be intentional challenge logic, debugging/instrumentation, or anti-debugging-related behavior. The important point for this program is that execution continues after it to the later logic.

`nop` literally does nothing.

---

# 11. The loop counter

The program initializes:

```asm
mov DWORD PTR [rbp-0x1c],0x0
```

So conceptually:

```c
int i = 0;
```

The stack variable is:

```text
[rbp-0x1c] → loop counter
```

The program then jumps to the loop condition.

---

# 12. Opening a file

The loop body contains:

```asm
mov esi,0x0
lea rax,[rip+0xe1b]
mov rdi,rax
mov eax,0x0
call open
```

The `lea` gets the address of a filename string. `mov rdi,rax` puts the filename pointer in the first argument register. `mov esi,0` sets the open flags argument to zero.

Conceptually:

```c
int fd = open(filename, 0);
```

The return value of `open` comes back in `RAX`.

The program then does:

```asm
mov ecx,eax
```

so the file descriptor is preserved in `ECX`.

---

# 13. Reading 8 bytes from the file

Next:

```asm
lea rax,[rbp-0x18]
mov edx,0x8
mov rsi,rax
mov edi,ecx
call read
```

The System V argument registers mean:

```text
RDI → file descriptor
RSI → destination buffer
RDX → number of bytes
```

Thus this is approximately:

```c
read(fd, &value, 8);
```

The local stack location:

```text
[rbp-0x18]
```

now contains the 8 bytes read from the file.

This gives a useful stack map:

```text
[rbp-0x08] → stack canary
[rbp-0x10] → user input
[rbp-0x18] → value read from file
[rbp-0x1c] → loop counter
[rbp-0x24] → argc
[rbp-0x30] → argv
[rbp-0x38] → envp
```

---

# 14. `puts` vs `printf`

A critical clarification:

> **`puts` vs `printf` is not determined by whether data came from a file or from user input.**

The source of the data does not determine the printing function.

## `puts`

`puts` prints a null-terminated string.

For example:

```c
char *msg = "Hello";
puts(msg);
```

A typical assembly pattern is:

```asm
lea rax,[rip+...]
mov rdi,rax
call puts
```

## `printf`

`printf` is used for formatted output:

```c
printf("input = %lx\n", input);
```

Typical calling-convention setup:

```text
RDI → format string
RSI → first formatting value
RDX → second formatting value
...
```

In this challenge, fixed text is frequently printed with `puts`, while values such as the user's input and the file value are printed with `printf`.

A good rule of thumb is:

```text
puts   → print a string
printf → print formatted data
```

Not:

```text
puts   = file data
printf = user data
```

---

# 15. User input via `scanf`

The program then does:

```asm
lea rax,[rbp-0x10]
mov rsi,rax
lea rax,[rip+0xe07]
mov rdi,rax
mov eax,0x0
call __isoc23_scanf
```

Break it down:

```asm
lea rax,[rbp-0x10]
mov rsi,rax
```

means:

```text
RSI = address of [rbp-0x10]
```

So `[rbp-0x10]` is where `scanf` will store the user's input.

Then:

```asm
lea rax,[rip+0xe07]
mov rdi,rax
```

puts the address of the input format string into `RDI`.

So the conceptual C statement is:

```c
scanf("format", &input);
```

The exact format string is not shown in this disassembly excerpt, so its exact specifier should not be invented.

---

# 16. Printing the user input

The program then executes:

```asm
mov rax,QWORD PTR [rbp-0x10]
mov rsi,rax
lea rax,[rip+0xdf1]
mov rdi,rax
mov eax,0x0
call printf
```

Conceptually:

```c
printf("...", input);
```

The important data flow is:

```text
[rbp-0x10]
    ↓
   RAX
    ↓
   RSI
    ↓
printf(format, input)
```

---

# 17. Printing the value read from the file

The program then executes:

```asm
mov rax,QWORD PTR [rbp-0x18]
mov rsi,rax
lea rax,[rip+0xde7]
mov rdi,rax
mov eax,0x0
call printf
```

Conceptually:

```c
printf("...", file_value);
```

Again, the origin of the data (file vs. user) is not what determines the function. `printf` is appropriate because a value is being inserted into a format string.

---

# 18. The actual comparison

The most important logic is:

```asm
mov rdx,QWORD PTR [rbp-0x10]
mov rax,QWORD PTR [rbp-0x18]
cmp rdx,rax
je  0x...d6a
```

Step by step:

```asm
mov rdx,[rbp-0x10]
```

→ `RDX = user input`

```asm
mov rax,[rbp-0x18]
```

→ `RAX = value read from file`

```asm
cmp rdx,rax
```

Conceptually compares:

```c
input - expected
```

without storing the subtraction result, but it changes CPU flags.

```asm
je ...
```

means **jump if equal**.

Conceptually:

```c
if (input == file_value)
    continue;
```

---

# 19. Failure path

Immediately after the comparison, the failure path is:

```asm
mov edi,0x1
call exit
```

Conceptually:

```c
exit(1);
```

Thus:

```c
if (input != expected)
    exit(1);
```

If the values are equal, execution continues.

---

# 20. Loop increment and number of iterations

The successful path contains:

```asm
add DWORD PTR [rbp-0x1c],0x1
cmp DWORD PTR [rbp-0x1c],0x3
jle 0x...cb1
```

This is approximately:

```c
i++;
if (i <= 3)
    goto loop_body;
```

Because `i` starts at zero, the loop runs for:

```text
i = 0
i = 1
i = 2
i = 3
```

Therefore there are **4 iterations**.

This is a useful reverse-engineering habit:

> Never interpret a comparison limit without also tracing the initialization and increment.

---

# 21. `win()`

After the loop succeeds:

```asm
mov eax,0x0
call 0x... <win>
```

Conceptually:

```c
win();
```

So the high-level objective of the challenge is to satisfy the check for all four iterations and reach `win()`.

---

# 22. Success message and return

After `win()` the program prints more text using the usual:

```asm
lea rax,[rip+...]
mov rdi,rax
call puts
```

Then:

```asm
mov eax,0x0
```

means:

```c
return 0;
```

---

# 23. Stack canary verification at function exit

The epilogue checks the saved stack canary:

```asm
mov rdx,QWORD PTR [rbp-0x8]
sub rdx,QWORD PTR fs:0x28
je  ...
call __stack_chk_fail
```

Conceptually:

```c
if (saved_canary != original_canary)
    __stack_chk_fail();
```

If unchanged, the function returns normally.

This is why the canary was saved near the beginning of the function.

---

# 24. Function epilogue

Finally:

```asm
leave
ret
```

`leave` is essentially:

```asm
mov rsp,rbp
pop rbp
```

It destroys the current stack frame.

`ret` pops the saved return address from the stack and transfers control back to whoever called the function.

This mirrors the earlier function prologue:

```text
PROLOGUE
push rbp
mov rbp,rsp
sub rsp,...

...

EPILOGUE
leave
ret
```

---

# 25. Reconstructed high-level C-like logic

Based strictly on the supplied disassembly, the important logic can be reconstructed approximately as:

```c
int main(int argc, char **argv, char **envp)
{
    // stack setup
    // stack canary setup

    setvbuf(stdin,  NULL, 2, 0);
    setvbuf(stdout, NULL, 2, 0);

    puts(...);
    printf(...);
    puts(...);
    // lots of challenge text

    int i = 0;

    while (i <= 3)
    {
        int fd = open(filename, 0);

        uint64_t expected;
        read(fd, &expected, 8);

        puts(...);
        printf(...);

        uint64_t input;
        scanf(..., &input);

        printf(..., input);
        printf(..., expected);

        if (input != expected)
            exit(1);

        i++;
    }

    win();
    puts(...);

    return 0;
}
```

This captures the high-level structure without inventing the exact string contents or file name from the truncated source view.

---

# 26. Why `[rbp-0x18]` is read again if we can inspect it in a debugger

This is a crucial reverse-engineering distinction.

The program does:

```asm
lea rax,[rbp-0x18]
mov edx,0x8
mov rsi,rax
mov edi,ecx
call read
```

After `read()` finishes:

```text
[rbp-0x18] = 8 bytes from the file
```

Later it does:

```asm
mov rax,[rbp-0x18]
```

That means **the CPU/program is reading the value back from memory** so it can use it in later instructions, especially the comparison.

A debugger can also inspect that same memory location, but that is **you observing the process state** rather than the program executing its own `mov` instruction.

So there are two meanings of “read”:

### Program reading memory

```asm
mov rax,[rbp-0x18]
```

→ CPU reads 8 bytes from memory into `RAX`.

### You inspecting memory

A debugger can show `[rbp-0x18]` to you.

→ You are observing the same memory location.

They are not contradictory.

---

# 27. Why this is especially useful for a challenge

Yes: this is exactly the kind of structure a reverse-engineering challenge often uses.

The program is effectively:

```text
FILE
 ↓
read 8 bytes
 ↓
[rbp-0x18]
 ↓
compare with user input
 ↓
wrong → exit(1)
right → next iteration
 ↓
after four successes → win()
```

Therefore, from a debugging/reversing perspective, a breakpoint after `read()` can allow you to inspect `[rbp-0x18]` and understand the expected value for that iteration.

The important distinction is that the program stores it in a local variable because `read()` needs a destination buffer and because the value is needed later for the comparison.

---

# 28. The most important reverse-engineering habit: data-flow analysis

When you see a comparison such as:

```asm
cmp rdx,rax
```

don't stop at the instruction itself.

Ask:

> Where did `RDX` come from?

Here:

```asm
mov rdx,[rbp-0x10]
```

So ask:

> Where did `[rbp-0x10]` come from?

Answer:

```asm
scanf(...,&[rbp-0x10])
```

Then:

> Where did `RAX` come from?

Answer:

```asm
mov rax,[rbp-0x18]
```

Then:

> Where did `[rbp-0x18]` come from?

Answer:

```asm
read(fd,&[rbp-0x18],8)
```

Then:

> Where did `fd` come from?

Answer:

```asm
open(...)
```

This is **data-flow tracing**.

A useful chain is:

```text
file
 ↓
read()
 ↓
[rbp-0x18]
 ↓
RAX
 ↓
cmp
 ↑
RDX
 ↑
[rbp-0x10]
 ↑
scanf()
 ↑
user
```

This mental model is much more powerful than memorizing every individual instruction.

---

# 29. Four categories to classify instructions while reading assembly

## A. Data movement

```asm
mov
lea
push
pop
```

Ask:

> Where is the data going?

## B. Computation

```asm
add
sub
xor
and
or
imul
```

Ask:

> What value is being calculated?

## C. Control flow

```asm
jmp
je
jne
jle
jg
call
ret
```

Ask:

> Where can execution go next?

## D. Memory/function interaction

Examples:

```asm
mov [memory]
call read
call scanf
call printf
call open
```

Ask:

> What data is entering or leaving the program?

This classification helps turn a large disassembly into a manageable mental model.

---

# 30. Stack map for this program

Keep this beside the disassembly:

```text
RBP
│
├── [rbp-0x08] → stack canary
│
├── [rbp-0x10] → user input
│
├── [rbp-0x18] → 8-byte value read from file
│
├── [rbp-0x1c] → loop counter
│
├── [rbp-0x24] → argc
│
├── [rbp-0x30] → argv
│
└── [rbp-0x38] → envp
```

This stack map is one of the most useful tools for following the function.

---

# 31. The central mental model

When reading whole programs, don't try to memorize the raw instruction stream.

Instead:

```text
Individual instructions
        ↓
Registers and memory
        ↓
Function arguments
        ↓
Control-flow structure
        ↓
Data-flow tracing
        ↓
Pseudocode / C-like reconstruction
        ↓
Reverse-engineering understanding
```

The real bottleneck is usually not instruction knowledge. It is **state tracking**.

---

# 32. What this challenge teaches

This one function contains nearly every major concept needed to start serious assembly reading:

- stack frames
- local variables
- `RBP` offsets
- `RIP`-relative addressing
- `LEA`
- System V AMD64 calling convention
- `open`
- `read`
- `scanf`
- `printf`
- `puts`
- `cmp`
- conditional jumps
- loops
- function calls
- stack canaries
- `int3`
- function epilogues
- data-flow analysis

The most valuable progression is:

> **Understand what one instruction does → understand what a short block does → understand the data moving through the block → reconstruct the larger control flow.**

---

# 33. Final takeaway

For this specific challenge, the simplest high-level description is:

```text
Initialize program
      ↓
Print challenge information
      ↓
Initialize i = 0
      ↓
Repeat while i <= 3
      ↓
Open the challenge file
      ↓
Read 8 bytes into [rbp-0x18]
      ↓
Ask the user for a value into [rbp-0x10]
      ↓
Compare user input with file value
      ↓
Wrong → exit(1)
      ↓
Correct → i++
      ↓
Repeat
      ↓
After four successful rounds → win()
      ↓
Return 0
```

The most useful questions to ask when reading future assembly are:

1. **What does this instruction do?**
2. **What value is in this register now?**
3. **Where did that value come from?**
4. **Where is that value going next?**
5. **What does this block of instructions accomplish as a whole?**
6. **Where can execution go next?**

Those six questions are the bridge from knowing assembly instructions to actually **reading programs in assembly**.
