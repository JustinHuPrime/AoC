section .text

extern writeNewline, writeLong

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

  ; for each of the 300 fish
  mov rcx, 300
.readFish:

  mov al, [r15] ; find the age of the fish
  sub al, '0'
  movzx rax, al

  mov rbx, [fish + (rax * 8)] ; increment that bin
  inc rbx
  mov [fish + (rax * 8)], rbx

  add r15, 2 ; skip this character and comma/newline

  loop .readFish

  ; for each of the 80 generations
  mov rcx, 256
.doGeneration:

  mov rax, [fish + (0 * 8)] ; rax = fish about to reproduce
  
  mov rbx, rcx ; save rcx

  lea rsi, [fish + (1 * 8)] ; move everyone down a bin
  lea rdi, [fish + (0 * 8)]
  mov rcx, 8
  rep movsq
  
  mov rcx, rbx ; restore rcx

  mov [fish + (8 * 8)], rax ; reproduce
  add [fish + (6 * 8)], rax ; return fish to their new bin

  loop .doGeneration

  mov rdi, 0
  add rdi, [fish + (0 * 8)]
  add rdi, [fish + (1 * 8)]
  add rdi, [fish + (2 * 8)]
  add rdi, [fish + (3 * 8)]
  add rdi, [fish + (4 * 8)]
  add rdi, [fish + (5 * 8)]
  add rdi, [fish + (6 * 8)]
  add rdi, [fish + (7 * 8)]
  add rdi, [fish + (8 * 8)]
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