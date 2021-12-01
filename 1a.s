section .text

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, rdonly
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statBuf
  syscall
  mov rdx, [statBuf + sizeOffset]
  mov r12, rdi

  mov rax, 12 ; save heap start in rbx
  mov rdi, 0
  syscall
  mov rbx, rax

  mov rax, 12 ; brk required space
  lea rdi, [rbx + rdx]
  syscall

  mov rax, 0 ; read file
  mov rdi, r12
  mov rsi, rbx
  ; mov rdx, rdx ; already have size in rdx
  syscall

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  mov rax, 1 ; write file as a check
  mov rdi, 1
  mov rsi, rbx
  ; mov rdx, rdx ; already have size in rdx
  syscall

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48
rdonly: equ 0

section .bss

statBuf:
  resb 144
writeBuf:
  resb 20
writeBufEnd: