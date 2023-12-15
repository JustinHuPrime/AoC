extern exit, mmap, putlong, newline

section .text

%define curr rbx
%define eof [rsp + 0]
%define hash al
%define accumulator rbp
%define seventeen r12b

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof/lastLine

  mov curr, rax
  add rax, rdx
  mov eof, rax

  mov seventeen, 17
.fileLoop:

  mov hash, 0
.stepLoop:
  ; read in character and update hash
  add hash, [curr]
  cbw
  mul seventeen

  inc curr

  cmp BYTE [curr], `\n`
  je .endStepLoop
  cmp BYTE [curr], ','
  jne .stepLoop
.endStepLoop:

  inc curr ; skip terminator

  movzx rax, hash
  add accumulator, rax

  cmp curr, eof
  jb .fileLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit
