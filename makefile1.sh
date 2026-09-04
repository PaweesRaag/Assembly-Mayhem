#!/bin/bash

# Assemble the x86-64 source file into an object file.
as -o $1.o $1.s

# Link the object as a shared object.
ld -shared -o $1.so $1.o

# Execute the generated shared object.
./$1.so

# Run the challenge checker against the shared object.
/challenge/check $1.so

# Remove build artifacts.
rm $1.o $1.so
