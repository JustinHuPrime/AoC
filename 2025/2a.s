extern exit, mmap, atol, putlong, newline, sputlong, findnotnum, puts

section .text

%define currChar r12
%define endOfFile r13
%define accumulator r15
%define currValue r14
%define endValue rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
  mov accumulator, 0
.loop:
  ; parse the start of the range
  mov rdi, currChar
  call findnotnum

  mov rdi, currChar
  mov rsi, rax
  lea currChar, [rax + 1]
  call atol

  mov currValue, rax

  ; parse the end of the range
  mov rdi, currChar
  call findnotnum

  mov rdi, currChar
  mov rsi, rax
  lea currChar, [rax + 1]
  call atol

  mov endValue, rax

  ; for all values from currValue to endValue inclusive
.innerLoop:
  ; print out the value
  mov rdi, currValue
  mov rsi, buffer
  call sputlong

  ; if there are an odd number of digits, early exit
  mov rcx, rdx
  sub rcx, rax ; rcx = number of digits
  test rcx, 0x1
  jnz .continueInnerLoop ; was odd, bail

  shr rcx, 1 ; rcx = number of digits in half

  ; do comparison
  mov rsi, rax
  lea rdi, [rax + rcx]
.compareLoop:
  cmpsb
  loope .compareLoop
  jne .continueInnerLoop ; if halves were not equal, bail

  ; halves were equal, this is invalid
  add accumulator, currValue

.continueInnerLoop:

  inc currValue

  cmp currValue, endValue
  jbe .innerLoop

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
buffer: resb 20
