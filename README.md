# ⚙️ Assembly Mayhem

> **Where high-level code stops making excuses and the machine starts explaining itself.**

`Assembly-Mayhem` is my hands-on x86-64 Linux playground for learning what actually happens underneath a program — one instruction, register, stack frame, syscall, and debugger session at a time.

This repository is the successor to my old **Playground**: less "I read about it", more **I wrote it, assembled it, ran it, broke it, and figured out why.**

---

## 🧠 What is this?

A living learning log for my progression from **assembly fundamentals → Linux internals → low-level debugging → exploit development**.

The goal isn't to make a perfectly polished collection of code. The goal is to preserve the process of figuring things out — including the mistakes, misconceptions, weird crashes, and the *"ohhh, that's what it actually does"* moments.

> **Mayhem is intentional. Understanding is the objective.**

---

## 🔬 Current Focus

### x86-64 Assembly
- Registers and instruction semantics
- Arithmetic and data representation
- Control flow and comparisons
- Memory and addressing
- Stack fundamentals
- Function calls and the calling convention
- Process entry and `argc` / `argv`
- Linux system calls
- Assembling, linking, and executing programs

### 🐧 Linux & Debugging
- Working directly from the Linux command line
- Compiling and running low-level programs
- Reading program behaviour instead of guessing
- Debugging execution step-by-step
- Inspecting registers, memory, and the stack
- Understanding what the CPU is actually doing

### 💥 Exploit Development
The longer-term direction of this repository is exploit development: building the low-level intuition required to understand how programs can be made to behave in unintended ways.

For now, the focus is on **earning that understanding from the ground up** rather than jumping straight to advanced exploitation techniques.

---

## 📚 Learning Path

```text
┌──────────────────────────┐
│   High-Level Programs    │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│     x86-64 Assembly      │
│ registers • instructions │
│ memory • arithmetic      │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│      Linux Internals     │
│ processes • syscalls     │
│ stack • memory           │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│       Debugging          │
│ execution • registers    │
│ memory • disassembly     │
└────────────┬─────────────┘
             ↓
┌──────────────────────────┐
│    Exploit Development   │
│ low-level vulnerability  │
│ research & exploitation  │
└──────────────────────────┘
```

The important part is the arrows. Each layer should make the next one easier to understand.

---

## 🧩 A Few Things I've Already Had to Learn the Hard Way

### `argc` isn't a number to fear

One of the early lessons: when working with program arguments, understanding **what the value represents** matters more than blindly manipulating it.

For example, an exercise involving numbers initially looked like a digit-summing problem. It turned out the program was dealing with **numbers as values**, not simply adding their individual decimal digits.

That distinction sounds tiny at a high level.

At assembly level, it forces you to think about representation, registers, instructions, and exactly what data is being operated on.

That's precisely why this stuff is fun.

---

## 🛠️ Workflow

My preferred learning loop is brutally simple:

```text
WRITE
  ↓
ASSEMBLE
  ↓
RUN
  ↓
BREAK
  ↓
DEBUG
  ↓
UNDERSTAND
  ↓
REPEAT
```

If something works but I don't understand *why*, the job isn't finished.

If something crashes, that's usually even better.

---

## 🎯 Long-Term Objectives

- [x] Start writing and executing x86-64 assembly
- [x] Work with program arguments and `argc` / `argv`
- [x] Get comfortable reasoning about low-level arithmetic
- [x] Assemble, execute, and debug my own programs
- [ ] Build stronger intuition for Linux processes and syscalls
- [ ] Become comfortable reading compiler-generated assembly
- [ ] Deepen stack and memory understanding
- [ ] Develop serious debugging and disassembly skills
- [ ] Progress into hands-on exploit development
- [ ] Turn individual experiments into reusable low-level knowledge

---

## 🧪 What's Inside

As this repository grows, expect things like:

```text
Assembly-Mayhem/
│
├── basics/          # Registers, instructions, arithmetic, control flow
├── arguments/       # argc, argv and process arguments
├── memory/          # Addressing, pointers and memory experiments
├── stack/           # Stack behaviour and calling conventions
├── syscalls/        # Linux syscall experiments
├── debugging/       # Debugger sessions and investigations
├── experiments/     # Things that exist mainly because I wondered "what if?"
└── notes/           # Lessons, mistakes and useful discoveries
```

> The structure will evolve as the learning does.

---

## 🏫 Learning Source

A major part of this progression comes from **pwn.college** and hands-on experimentation.

But this repository isn't intended to be a copy of a course.

It's my record of what **I actually understood, implemented, debugged, and learned along the way.**

---

## 🧠 Philosophy

> **Don't memorize the instruction. Understand the machine.**

I want to get to the point where I can look at a piece of assembly and reason about:

- what values exist,
- where they live,
- how they move,
- what the CPU will do next,
- what the operating system is doing,
- and why a program behaves the way it does.

That mental model is the real end goal.

---

## 📈 The Mayhem Log

This repository will gradually become a chronological record of the journey.

Every experiment should answer at least one question:

> **What did I understand after doing this that I didn't understand before?**

Some entries will be clean.
Some will be embarrassingly wrong.
Some will probably segfault spectacularly.

All of them count.

---

## ⚠️ Disclaimer

Everything here is for **education, experimentation, and authorized security research**. Exploit-development material should only be applied to systems and environments where I have explicit permission to test.

---

## 🚀 Status

**Active. Constantly evolving. Occasionally segfaulting.**

This isn't the finished product.

It's the evidence that I'm building it.

---

<p align="center">
  <b>⚙️ Learn the instructions. Understand the system. Then break things responsibly. 💥</b>
</p>
