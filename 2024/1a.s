extern exit, mmap, findws, atol, skipws, putlong, newline, qsort

section .text

%define endOfFile r12
%define curr r13
%define numLines r14
%define accumulator r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov curr, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
  ; load numbers, count numbers
  mov numLines, 0
.countLineLoop:
  mov rdi, curr
  call findws

  mov rdi, curr
  mov rsi, rax
  mov curr, rax
  call atol

  mov [leftList + numLines * 8], rax
  
  mov rdi, curr
  call skipws
  mov curr, rax

  mov rdi, curr
  call findws

  mov rdi, curr
  mov rsi, rax
  mov curr, rax
  call atol

  mov [rightList + numLines * 8], rax

  inc numLines

  inc curr
  cmp curr, endOfFile
  jb .countLineLoop

  ; sort lists
  mov rdi, leftList
  mov rsi, leftList + 1000 * 8
  call qsort

  mov rdi, rightList
  mov rsi, rightList + 1000 * 8
  call qsort

  ; calculate
  mov curr, 0
  mov accumulator, 0
.differenceLoop:

  mov rax, [leftList + curr * 8]
  mov rdx, [rightList + curr * 8]

  sub rax, rdx ; rax = left - right
  mov rdx, rax ; rdx = right - left
  neg rdx
  test rax, rax
  cmovs rax, rdx ; if rax is negative, use rdx instead

  add accumulator, rax

  inc curr
  cmp curr, numLines
  jb .differenceLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
leftList:
  resq 1000
rightList:
  resq 1000