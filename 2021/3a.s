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

  ; while current < end (r13 = current position)
.countLoop:
  cmp r13, r12
  jge .countLoopEnd

  ; for each of the 12 bits
  mov rcx, 12
.countBitLoop:

  mov sil, [r13] ; if character is 1 increment the count
  sub sil, '0'
  movzx rsi, sil
  add [oneCounts + (rcx * 8) - 8], rsi

  inc r13 ; done with this character

  loop .countBitLoop

  inc r13 ; skip newline

  jmp .countLoop
.countLoopEnd:

  mov r15, 0 ; r15 = working number

  ; for each of the 12 bits
  mov rcx, 12
.sumBitLoop:

  shl r15, 1 ; shift left to make room for next bit

  mov rsi, [oneCounts + (rcx * 8) - 8] ; if it's greater than 500, increment the last bit
  lea r14, [r15 + 1]
  cmp rsi, 500
  cmovg r15, r14

  loop .sumBitLoop

  mov rdi, r15 ; rdi = least common bits = ~most common bits
  not rdi
  and rdi, 0xfff ; but keep only the last twelve bits

  imul rdi, r15 ; print final answer
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
oneCounts:
  resq 12