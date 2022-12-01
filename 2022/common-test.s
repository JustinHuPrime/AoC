section .text

extern writeLong, exit, newline

global _start:function
_start:
  mov rdi, 902347590
  call writeLong

  call newline

  mov dil, al
  call exit