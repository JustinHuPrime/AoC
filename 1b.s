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
  mov r14, 0 ; r14 = number of numbers pushed

  ; while current < end
.parseLoop:
  cmp r13, r12
  jge .parseLoopEnd

  mov rdi, r13 ; get address of newline
  call findNewline

  mov rsi, rax ; get value of number
  call atol

  push ax ; push number onto stack
  inc r14 ; increment number of numbers pushed

  lea r13, [rsi + 1] ; current position = address of newline + 1

  jmp .parseLoop
.parseLoopEnd:

  mov r15, 0 ; r15 = number of increases

  ; while there's at least four numbers on the stack (while r14 >= 4)
.countLoop:
  cmp r14, 4
  jl .countLoopEnd

  pop ax ; get last number of lower three
  mov bx, [rsp + 2 * 2] ; get first number of upper three

  lea r11, [r15 + 1] ; if last > first, increment r15
  cmp ax, bx
  cmovg r15, r11

  dec r14 ; decrement number of numbers pushed

  jmp .countLoop
.countLoopEnd:

  sub rsp, 6 ; pop the last three numbers

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