section .text

extern atol, writeNewline, writeLong, findNewline

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, O_RDONLY
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statBuf
  syscall
  mov rsi, [statBuf + sizeOffset] ; rsi = length of file
  mov r12, rdi ; r12 = fd

  mov rax, 9 ; mmap the file
  mov rdi, 0
  ; mov rsi, rsi ; already have size of file
  mov rdx, PROT_READ
  mov r10, MAP_PRIVATE
  mov r8, r12
  mov r9, 0
  syscall
  mov r13, rax ; r13 = start of file

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  lea r12, [r13 + rsi] ; r12 = end of file

  mov rdi, r13
  call findNewline
  
  mov rsi, rax
  call atol
  mov r14, rax ; r14 = last value
  mov r15, 0 ; r15 = number of times increased

  ; while current < end
.loop:
  cmp r13, r12
  jge .end

  mov rdi, r13 ; get address of newline
  call findNewline

  mov rsi, rax ; get value of number
  call atol

  lea r11, [r15 + 1] ; if value > previous, increase count
  cmp rax, r14
  cmovg r15, r11

  ; push rsi ; display number as a check

  ; mov rdi, rax
  ; call writeLong
  ; call writeNewline
  
  ; pop rsi

  lea r13, [rsi + 1] ; current position = address of newline + 1
  mov r14, rax ; previous = value

  jmp .loop
.end:

  mov rdi, r15 ; print r15
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144