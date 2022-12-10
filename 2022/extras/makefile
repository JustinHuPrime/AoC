.SUFFIXES:
.SECONDARY:

nodefault:
	@echo "No default target is applicable"
	@exit 1

%.o: %.s
	nasm -f elf64 $^

10a-cross: 10a-cross.o ../common.o
	ld -o $@ $^

10b-cross: 10b-cross.o ../common.o
	ld -o $@ $^

../%.txt:
	$(MAKE) -C .. $*.txt

run-10a-cross: 10a-cross ../10.txt
	./$^ > a.out
	chmod +x a.out
	./a.out

run-10b-cross: 10b-cross ../10.txt
	./$^ > a.out
	chmod +x a.out
	./a.out