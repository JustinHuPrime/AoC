extern exit, mmap, putlong, newline, findnotnum, atol

section .text

%define endOfFile r12
%define currChar r13
%define firstNum r14
%define firstLen rbx
%define accumulator r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  mov accumulator, 0

.loop:

  cmp DWORD [currChar], 'mul('
  jne .continueLoop

  lea rdi, [currChar + 4]
  call findnotnum

  mov rsi, rax ; rsi = end of parsed number
  lea rdi, [currChar + 4]
  sub rax, rdi
  mov firstLen, rax

  cmp firstLen, 1
  jb .continueLoop
  cmp firstLen, 3
  ja .continueLoop

  lea rdi, [currChar + 4]
  ; mov rsi, rsi
  call atol
  mov firstNum, rax

  cmp BYTE [currChar + 4 + firstLen], ','
  jne .continueLoop

  lea rdi, [currChar + 5 + firstLen]
  call findnotnum

  mov rsi, rax ; rsi = end of parsed number
  lea rdi, [currChar + 5 + firstLen]
  sub rax, rdi

  cmp rax, 1
  jb .continueLoop
  cmp rax, 3
  ja .continueLoop
  mov rbp, rax

  lea rdi, [currChar + 5 + firstLen]
  ; mov rsi, rsi
  call atol

  add firstLen, rbp
  cmp BYTE [currChar + 5 + firstLen], ')'
  jne .continueLoop

  mul firstNum

  add accumulator, rax

.continueLoop:

  inc currChar

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit
