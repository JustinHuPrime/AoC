SRCS = $(shell find src -type f -name '*.s')

raytracer: $(SRCS:%.s=%.o) | $(dir $@)
	ld -o $@ $^

%.o: %.s
	nasm -f elf64 $^
