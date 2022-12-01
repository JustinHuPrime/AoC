.SUFFIXES:
.SECONDARY:
.PHONY: all

all: common-test

%.o: %.s
	nasm -f elf64 $^

%: %.o common.o
	ld -o $@ $^