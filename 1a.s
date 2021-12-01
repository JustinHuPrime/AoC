extern _end

section .text

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  ; sub rsp, 0
  ; locals:
  ; none

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, 0
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statbuf
  syscall
  mov rdx, [statbuf + sizeOffset]
  mov r12, rdi

  mov rax, 12 ; brk required space
  lea rdi, [_end + rdx]
  syscall

  mov rax, 0 ; read file
  mov rdi, r12
  mov rsi, _end
  ; mov rdx, rdx ; already have size in rdx
  syscall

  mov rax, 1 ; write file as a check
  mov rdi, 1
  mov rsi, _end
  ; mov rdx, rdx ; already have size in rdx
  syscall

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48

section .bss

statbuf:
  resb 144