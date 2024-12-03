extern exit, mmap, putlong, newline, findnotnum, atol

section .text

%define endOfFile [rsp + 0]
%define currChar r13
%define firstNum r14
%define firstLen rbx
%define accumulator r15
%define active r12b

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = endOfFile

  mov currChar, rax
  add rax, rdx
  mov endOfFile, rax

  mov accumulator, 0
  mov active, 1

.loop:

  ; check - is this a do instruction
  mov rcx, 4
  mov rsi, currChar
  mov rdi, do
  repe cmpsb
  jne .notDo

  mov active, 1

  jmp .continueLoop
.notDo:

  ; check - is this a don't instruction
  mov rcx, 6
  mov rsi, currChar
  mov rdi, dont
  repe cmpsb
  jne .notDont

  mov active, 0

  jmp .continueLoop
.notDont:

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

  mov rbp, 0
  test active, active
  cmovz rax, rbp
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

section .rodata
do: db "do()"
dont: db "don't()"
