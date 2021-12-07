section .text

extern writeNewline, writeLong, atol, findChar, qsortLong

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

  mov rdi, numbers ; sort numbers
  lea rsi, [numbers + (1000 * 8)]
  call qsortLong

  mov rsi, [numbers + (499 * 8)] ; get the median
  add rsi, [numbers + (500 * 8)]
  shr rsi, 1

  ; for each of the 1000 numbers
  mov rcx, 1000
  mov rdi, 0 ; rdi = sum of differences
.differenceLoop:
  mov rax, [numbers + (rcx * 8) - 8] ; get number
  sub rax, rsi ; get the difference
  mov rbx, rax
  neg rbx
  cmovns rax, rbx ; if number is negative, make it positive

  add rdi, rax ; add the difference to the sum

  loop .differenceLoop

  ; mov rdi, rdi ; already got rdi
  call writeLong
  call writeNewline ; TODO: compute distances from median

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