extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile r13
%define accumulator r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; do-while currChar < endOfFile
  mov accumulator, 0
.loop:

  ; find largest battery that's not the last one for 10s place
  mov rsi, currChar
  mov rax, rsi ; rax = pointer to largest so far
.findLargestLoop:

  mov cl, [rsi]
  cmp cl, [rax]
  cmova rax, rsi

  inc rsi

  cmp BYTE [rsi + 1], `\n`
  jne .findLargestLoop

  ; find second-largest battery after first one for 1s place
  lea rsi, [rax + 1]
  mov rdx, rsi ; rdx = pointer to largest so far
.findSecondLargestLoop:

  mov cl, [rsi]
  cmp cl, [rdx]
  cmova rdx, rsi

  inc rsi

  cmp BYTE [rsi], `\n`
  jne .findSecondLargestLoop

  ; done with this line
  lea currChar, [rsi + 1]

  ; convert digits to value
  movzx rax, BYTE [rax]
  sub rax, '0'
  movzx rdx, BYTE [rdx]
  sub rdx, '0'

  imul rax, rax, 10
  add rax, rdx

  add accumulator, rax

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit