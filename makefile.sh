#!/bin/bash

# Show usage information.
if [ "$1" = "-h" ]; then
    echo "Usage: ./makefile <program>"
    echo
    echo "Build and run an x86-64 assembly program."
    echo
    echo "Arguments:"
    echo "  <program>    Name of the assembly file without .s"
    echo
    echo "Examples:"
    echo "  ./makefile program"
    echo "  ./makefile -h"
    exit 0
fi

# Assemble the source file into an object file.
as -o "$1.o" "$1.s"

# Link the object file into an executable.
ld -o "$1" "$1.o"

# Run the assembled program.
./"$1"

# Run the challenge checker against the executable.
/challenge/check ./$1

# Remove temporary build artifacts.
rm $1.o ./$1
