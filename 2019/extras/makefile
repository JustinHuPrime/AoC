.PHONY: all
.SUFFIXES:

all: intcode-as intcode-num-adaptor-in intcode-num-adaptor-out intcode-ascii-adaptor-in intcode-ascii-adaptor-out

%: %.o common.o
	ld -o $@ $^

%.o: %.s
	nasm -f elf64 $^

%-cross: intcode-as ../%.txt
	./$^ > $@
	chmod +x $@
