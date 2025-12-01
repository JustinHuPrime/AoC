extern exit, mmap, findnl, atol, putlong, newline

section .text

%define currChar r12
%define endOfFile r13
%define currValue r14
%define accumulator r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
  mov currValue, 50
  mov accumulator, 0
.loop:
  ; bl = 'L' or 'R'
  mov bl, [currChar]

  ; find the end of this line
  mov rdi, currChar
  call findnl

  ; parse the number part of this line
  mov rsi, rax
  lea rdi, [currChar + 1]
  lea currChar, [rax + 1]
  call atol

  ; if we're moving left, negate the result
  mov rdi, rax
  neg rdi
  cmp bl, 'L'
  cmove rax, rdi

  ; change the dial position
  add rax, currValue
  cqo
  mov rbx, 100
  idiv rbx
  
  ; remainder in rdx, convert to modulus by adding 100
  lea rax, [rdx + 100]
  test rdx, rdx
  cmovs rdx, rax
  mov currValue, rdx

  ; increment accumulator if currValue == 0
  lea rax, [accumulator + 1]
  test currValue, currValue
  cmovz accumulator, rax

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit