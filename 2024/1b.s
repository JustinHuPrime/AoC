extern exit, mmap, findws, atol, skipws, putlong, newline, qsort

section .text

%define endOfFile r12
%define curr r13
%define numLines r14
%define accumulator r12
%define leftCurr r13
%define rightCurr r15

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
  mov leftCurr, 0
  mov rightCurr, 0
  mov accumulator, 0
.differenceLoop:

  ; get left-hand list number
  mov rax, [leftList + leftCurr * 8]
  inc leftCurr

  ; skip right-hand numbers until we see one >= left hand list number
.skipRightLoop:
  mov rdx, [rightList + rightCurr * 8]
  cmp rax, rdx
  jle .endSkipRightLoop

  inc rightCurr

  jmp .skipRightLoop
.endSkipRightLoop:

  ; count right-hand list occurrences
  mov rdi, 0 ; rdi = number of times seen
.countRightLoop:
  mov rdx, [rightList + rightCurr * 8]
  cmp rax, rdx
  jne .endCountRightLoop

  inc rightCurr
  inc rdi

  jmp .countRightLoop
.endCountRightLoop:

  mul rdi

  add accumulator, rax

  cmp leftCurr, numLines
  jb .differenceLoop
  cmp rightCurr, numLines
  jb .differenceLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
leftList:
  resq 1001
rightList:
  resq 1001