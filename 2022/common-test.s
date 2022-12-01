section .text

extern putlong, exit, newline

global _start:function
_start:
  mov rdi, 902347590
  call putlong

  call newline

  mov dil, 0
  call exit