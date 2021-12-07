#!/usr/bin/env fish

nasm -f elf64 $argv[1].s
nasm -f elf64 ../common/common.s
ld -o $argv[1] $argv[1].o ../common/common.o