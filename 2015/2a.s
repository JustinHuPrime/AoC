section .text

extern writeNewline, writeLong, atol, findChar, findNewline

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

  ; for each line in the file
  mov r14, 1000
  mov rbx, 0 ; rbx = amount of paper needed so far
.loop:

  mov rdi, r15
  mov sil, 'x'
  call findChar
  mov rsi, rax
  call atol

  mov r8, rax ; r8 = first dimension

  lea rdi, [rsi + 1]
  mov sil, 'x'
  call findChar
  mov rsi, rax
  call atol

  mov r9, rax ; r9 = second dimension

  lea rdi, [rsi + 1]
  call findNewline
  mov rsi, rax
  call atol

  mov r10, rax ; r10 = third dimension

  lea r15, [rsi + 1] ; move to next line

  mov r11, r8
  imul r11, r9 ; r11 = first side

  mov r12, r9
  imul r12, r10 ; r12 = second side

  mov r13, r10
  imul r13, r8 ; r13 = third side

  mov r10, r11
  cmp r10, r12
  cmovg r10, r12
  cmp r10, r13
  cmovg r10, r13 ; r10 = smallest side

  add rbx, r11 ; add twice each side
  add rbx, r11
  add rbx, r12
  add rbx, r12
  add rbx, r13
  add rbx, r13
  add rbx, r10 ; and add the smallest side

  dec r14
  cmp r14, 0
  jg .loop

  mov rdi, rbx
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
fish:
  resq 9