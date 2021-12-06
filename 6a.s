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

  mov r8, fish ; r8 = end of the fish

  ; for each of the 300 fish
  mov rcx, 300
.readFish:

  mov al, [r15] ; get the next character and save it to fish
  sub al, '0'
  mov [r8], al

  inc r8 ; got another fish

  add r15, 2 ; skip this character and comma/newline

  loop .readFish

  ; for each of the 80 generations
  mov rcx, 80
.doGeneration:

  mov r9, fish ; r9 = current fish
  mov r10, r8 ; r10 = end of the current fish

  ; for all fish from r9 to r10
.doFish:

  mov al, [r9] ; get the fish
  test al, al ; if it's a zero, reproduce
  jz .reproduce
  ; no reproduction

  dec al
  mov [r9], al ; decrease cooldown

  jmp .doneFish
.reproduce:
  ; reproduction

  mov BYTE [r9], 6 ; reset cooldown
  mov BYTE [r8], 8 ; got a new fish
  inc r8

.doneFish:

  inc r9

  cmp r9, r10
  jl .doFish

  loop .doGeneration

  mov rdi, r8
  sub rdi, fish
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
  resb 8*1024*1024