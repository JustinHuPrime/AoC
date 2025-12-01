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

  ; if currValue is zero and bl = 'L' (i.e. we will leave zero by going left), subtract one (we will overcount)
  test currValue, currValue
  jnz .skipAdjust2
  cmp bl, 'L'
  jne .skipAdjust2
  dec accumulator
.skipAdjust2:

  ; change the dial position
  add rax, currValue
  cqo
  mov rsi, 100
  idiv rsi

  ; abs rax = how many times the dial cycled around fully to get to the current position
  mov rsi, rax
  neg rsi
  test rax, rax
  cmovns rsi, rax
  add accumulator, rsi
  
  ; remainder in rdx, convert to modulus by adding 100
  ; negative remainder also indicates an extra cycle
  lea rcx, [rdx + 100]
  lea rsi, [accumulator + 1]
  test rdx, rdx
  cmovs rdx, rcx
  cmovs accumulator, rsi
  mov currValue, rdx

  ; if currValue = 0 and bl = 'L' (i.e. we got to zero by going left), add one
  cmp bl, 'L'
  jne .skipAdjust1
  test currValue, currValue
  jnz .skipAdjust1
  inc accumulator
.skipAdjust1:

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit