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

  ; initialize map to 255 everywhere
  mov al, 255
  mov rdi, map
  mov rcx, 102*102
  rep stosb

  ; read the map - for each of 100 lines
  mov rax, 102
.readLine:  

  mov rbx, 1
.readColumn:

  mov dil, [r15]
  sub dil, '0'
  mov [map + rax + rbx], dil

  inc r15 ; done with character

  inc rbx

  cmp rbx, 101
  jl .readColumn

  inc r15 ; skip newline

  add rax, 102

  cmp rax, 101*102
  jl .readLine

  mov r14, 0 ; r14 = risk level so far

  ; for each of the 100 lines
  mov rax, 102
.considerLine:

  mov rbx, 1
.considerColumn:
  
  mov dil, [map + rax + rbx]
  cmp dil, [map + rax + rbx + 1]
  jae .notLow
  cmp dil, [map + rax + rbx - 1]
  jae .notLow
  cmp dil, [map + rax + rbx + 102]
  jae .notLow
  cmp dil, [map + rax + rbx - 102]
  jae .notLow

  inc dil
  movzx rdi, dil
  add r14, rdi

.notLow:

  inc rbx

  cmp rbx, 101
  jl .considerColumn

  add rax, 102

  cmp rax, 101*102
  jl .considerLine

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
map:
  resb 102*102