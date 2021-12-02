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

  mov rdi, 0 ; rdi = forward position
  mov r15, 0 ; r15 = depth

  ; while current < end (r13 = current position)
.loop:
  cmp r13, r12
  jge .end

  mov sil, [r13] ; get first character of string
  cmp sil, 'f'
  je .forward  ; was forward
  jl .down ; was down
  ; jg .up ; was up

.up:

  add r13, 3 ; skip to the number
  mov sil, [r13] ; grab the number
  sub sil, '0' ; convert digit to value
  movzx rsi, sil ; subtract from depth
  sub r15, rsi

  jmp .doneMove

.down:

  add r13, 5 ; skip to the number
  mov sil, [r13] ; grab the number
  sub sil, '0' ; convert digit to value
  movzx rsi, sil ; add to depth
  add r15, rsi

  jmp .doneMove

.forward:

  add r13, 8 ; skip to the number
  mov sil, [r13] ; grab the number
  sub sil, '0' ; convert digit to value
  movzx rsi, sil ; add to forward
  add rdi, rsi

  ; jmp .doneMove

.doneMove:

  add r13, 2 ; move to the next direction

  jmp .loop
.end:

  imul rdi, r15
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