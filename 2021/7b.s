section .text

extern writeNewline, writeLong, atol, findChar, minLong, maxLong

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

  ; read numbers

  mov r8, 0 ; r8 = index of number read
  ; do ... while r8 < 1000
.readLoop:
  mov sil, ','
  mov dil, 0xa
  cmp r8, 999
  cmove rsi, rdi
  mov rdi, r15
  call findChar ; find a comma (or a newline if this is the last number)
  mov rsi, rax
  call atol
  mov [numbers + (r8 * 8)], rax ; save it

  lea r15, [rsi + 1]
  inc r8

  cmp r8, 1000
  jl .readLoop

  mov rdi, numbers
  lea rsi, [numbers + (1000 * 8)]
  call minLong
  mov r8, rax

  mov rdi, numbers
  call maxLong
  mov r9, rax

  ; for all gathering points from r8 to r9
  mov rdi, 0x7fffffffffffffff ; rdi = cost of gathering point
.searchLoop:

  ; compute the cost of gathering at r8
  mov rcx, 1000
  mov r11, 0 ; r11 = cost of gathering at r8 so far
.costLoop:

  mov r12, [numbers + (rcx * 8) - 8] ; r12 = number
  sub r12, r8
  mov r13, r12
  neg r13
  cmovns r12, r13 ; r12 = abs(r12)

  mov r13, r12
  inc r13
  imul r12, r13
  shr r12, 1 ; r12 = sum of first r12 numbers

  add r11, r12

  loop .costLoop

  cmp r11, rdi
  cmovl rdi, r11

  inc r8

  cmp r8, r9
  jl .searchLoop

  ; mov rdi, rdi
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