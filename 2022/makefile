.SUFFIXES:
.SECONDARY:
.PHONY: nodefault

nodefault:
	@echo "No default target is applicable"
	@exit 1

run-%a: %a %.txt
	./$^

run-%b: %b %.txt
	./$^

%.o: %.s
	nasm -f elf64 $^

%a: %a.o common.o
	ld -o $@ $^

%b: %b.o common.o
	ld -o $@ $^