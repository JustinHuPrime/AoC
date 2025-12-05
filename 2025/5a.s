extern mmap, putlong, newline, exit, countc, alloc, findc, atol

section .text

%define currChar r12
%define endOfFile r13
%define accumulator r14
%define ranges r15
%define currRange rbp
%define endRanges rbx

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  
  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; figure out how many fresh ranges there are and allocate
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, '-'
  call countc

  mov rdi, rax
  shl rdi, 4
  mov endRanges, rdi
  call alloc
  mov ranges, rax
  add endRanges, ranges

  ; load ranges
  mov currRange, ranges
.loadRangeLoop:

  ; find and read first part
  mov rdi, currChar
  mov sil, `-`
  call findc

  mov rdi, currChar
  lea currChar, [rax + 1]
  mov rsi, rax
  call atol

  mov [currRange + 0], rax

  ; find and read second part
  mov rdi, currChar
  mov sil, `\n`
  call findc

  mov rdi, currChar
  lea currChar, [rax + 1]
  mov rsi, rax
  call atol

  mov [currRange + 8], rax

  add currRange, 16

  cmp BYTE [currChar], `\n`
  jne .loadRangeLoop

  ; check each remaining ingredient id
  inc currChar
  mov accumulator, 0
.checkIngredientLoop:

  ; find and read ingredient
  mov rdi, currChar
  mov sil, `\n`
  call findc

  mov rdi, currChar
  lea currChar, [rax + 1]
  mov rsi, rax
  call atol

  ; is rax in any range?
  mov currRange, ranges
.checkRangeLoop:

  ; is rax in this range?
  cmp rax, [currRange + 0]
  jb .continueCheckRangeLoop
  cmp rax, [currRange + 8]
  ja .continueCheckRangeLoop

  ; yes - add to accumulator
  inc accumulator
  jmp .breakCheckRangeLoop

.continueCheckRangeLoop:
  add currRange, 16

  cmp currRange, endRanges
  jb .checkRangeLoop
.breakCheckRangeLoop:

  cmp currChar, endOfFile
  jb .checkIngredientLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit