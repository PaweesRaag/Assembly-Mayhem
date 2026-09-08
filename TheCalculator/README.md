# TheCalculator

A minimal command-line calculator implemented directly in x86-64 assembly (Intel syntax) for Linux.

## Overview

TheCalculator parses operands supplied through `argv`, performs an arithmetic or bitwise operation, converts the signed result back to decimal text, and writes the result directly to standard output using Linux system calls.

The project was built incrementally while studying low-level concepts including:

- Linux process startup and `argc`/`argv`
- x86-64 registers and addressing
- ASCII string parsing
- signed integer representation and two's complement
- calling conventions
- stack usage and temporary storage
- arithmetic and bitwise instructions
- direct Linux system calls

## Supported Operations

### Binary

```text
A + B    Addition
A - B    Subtraction
A * B    Multiplication
A ^ B    Bitwise XOR
A | B    Bitwise OR
A & B    Bitwise AND
```

### Unary

```text
- A      Arithmetic negation
~ A      Bitwise NOT
```

Examples:

```console
$ ./calculator 12 + 30
42

$ ./calculator 12 - 30
-18

$ ./calculator 7 ^ 3
4

$ ./calculator - 5
-5

$ ./calculator '~' 5
-6
```

## Architecture

The program follows a simple pipeline:

```text
argv
  |
  +--> atoi() --> integer operands
  |
  +--> operator dispatch
            |
            +--> arithmetic / bitwise operation
            |
            +--> itoa() --> decimal text
                              |
                              +--> write() --> stdout
```

The program distinguishes unary and binary expressions using `argc`:

```text
argc = 4  ->  prog A OP B
argc = 3  ->  prog OP A
```

## Implementation Details

### Argument handling

At `_start`, Linux places `argc` at `[rsp]` and the `argv` pointer table immediately above it. The implementation reads the relevant argument pointers directly from the initial stack layout.

### `atoi`

`atoi` accepts a pointer to a signed decimal string in `RDI` and returns the parsed integer in `RAX`.

It:

1. Checks for an optional leading `-`.
2. Scans ASCII digits from `0x30` through `0x39`.
3. Builds the value using `value = value * 10 + digit`.
4. Applies `neg` when the input was negative.

### Operation dispatch

The operator string is dereferenced and compared against the supported ASCII operator bytes. Each branch leaves the operation result in `RAX` before entering the common output path.

### `itoa`

`itoa` converts a signed integer in `RDI` into decimal text at the buffer pointed to by `RSI`.

Repeated division by 10 produces digits from least-significant to most-significant. The implementation therefore pushes the remainders onto the stack and pops them back in reverse order to produce normal decimal order.

Negative values receive a leading `-`, and zero is handled as a special case.

### System calls

The program uses Linux x86-64 system calls directly rather than a C runtime or standard library.

```text
write:
    RAX = 1
    RDI = file descriptor
    RSI = buffer
    RDX = byte count

exit:
    RAX = 60
    RDI = exit status
```

## Why this is a useful low-level project

The calculator is intentionally small, but it demonstrates how a seemingly high-level operation can be assembled from primitive mechanisms:

- command-line parsing from the process entry stack
- conversion between byte strings and integers
- signed arithmetic and two's-complement semantics
- bitwise operations (`and`, `or`, `xor`, `not`)
- function calls and register conventions
- explicit stack management
- direct interaction with the Linux syscall interface

Rather than relying on `atoi`, `printf`, or other library routines, the core conversion and output logic is implemented manually in assembly.

## Limitations

This is an educational calculator rather than a production expression evaluator. It supports a fixed set of unary and binary operators and expects command-line arguments in the forms described above. It does not implement precedence, parenthesized expressions, floating-point arithmetic, error reporting, or a general-purpose parser.

## Build

```console
as -o TheCalculator.o TheCalculator.s
ld -o TheCalculator TheCalculator.o
```

## Project Context

TheCalculator is part of an ongoing x86-64 assembly learning project focused on understanding low-level execution, data representation, control flow, calling conventions, string processing, and Linux system interfaces.