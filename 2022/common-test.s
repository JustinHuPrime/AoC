section .text

extern mmap, exit

global _start:function
_start:
  mov rdi, [rsp + 16] ; get argv[0]
  call mmap

  mov rsi, rax ; part to print
  mov rax, 1
  mov rdi, 1
  ; mov rdx, rdx
  syscall

  mov dil, 0
  call exit