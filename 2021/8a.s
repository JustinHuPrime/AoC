section .text

extern writeNewline, writeLong, findWs, findChar

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
  mov r15, rax ; r15 = current position in file

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  mov r14, 0 ; r14 = count of digits 1, 4, 7, 8
  mov rax, r15

  ; for each of the 200 lines
  mov rcx, 200
.lineLoop:

  mov rdi, rax ; find the bar
  mov sil, '|'
  call findChar

  inc rax ; move to the space after the bar

  mov r12, rcx

  ; for each of the four digits
  mov rcx, 4
.digitLoop:

  lea rdi, [rax + 1] ; move to the start of the number
  call findWs ; find the space/newline
  mov rsi, rax

  sub rsi, rdi ; if it's 2, 3, 4, or 8 long, increment r14
  lea r13, [r14 + 1]
  cmp rsi, 2
  cmove r14, r13
  cmp rsi, 3
  cmove r14, r13
  cmp rsi, 4
  cmove r14, r13
  cmp rsi, 7
  cmove r14, r13
  
  loop .digitLoop

  mov rcx, r12

  loop .lineLoop

  mov rdi, r14
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
numbers:
  resq 1000