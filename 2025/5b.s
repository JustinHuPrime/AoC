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
  call alloc
  mov ranges, rax

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

  ; adjust start - move it to one past the end of any range it's currently in
  ; until it stops being in a range
.adjustStartLoop:

  ; for each range
  mov rdi, ranges
.adjustStartRangeLoop:
  cmp rdi, currRange
  jae .endAdjustStartRangeLoop

  ; is start in that range?
  cmp rax, [rdi + 0]
  jb .continueAdjustStartRangeLoop
  cmp rax, [rdi + 8]
  ja .continueAdjustStartRangeLoop

  ; yes - move it and adjust again
  mov rax, [rdi + 8]
  inc rax
  jmp .adjustStartLoop
.endAdjustStartLoop

.continueAdjustStartRangeLoop:
  add rdi, 16
  jmp .adjustStartRangeLoop

.endAdjustStartRangeLoop:

  mov [currRange + 0], rax

  ; find and read second part
  mov rdi, currChar
  mov sil, `\n`
  call findc

  mov rdi, currChar
  lea currChar, [rax + 1]
  mov rsi, rax
  call atol

  ; adjust end - move it to one before the start of any range it's currently in
  ; until it stops being in a range
.adjustEndLoop:

  ; for each range
  mov rdi, ranges
.adjustEndRangeLoop:
  cmp rdi, currRange
  jae .endAdjustEndRangeLoop

  ; is start in that range?
  cmp rax, [rdi + 0]
  jb .continueAdjustEndRangeLoop
  cmp rax, [rdi + 8]
  ja .continueAdjustEndRangeLoop

  ; yes - move it and adjust again
  mov rax, [rdi + 0]
  dec rax
  jmp .adjustEndLoop

.continueAdjustEndRangeLoop:
  add rdi, 16
  jmp .adjustEndRangeLoop

.endAdjustEndRangeLoop:

  mov [currRange + 8], rax

  ; if this is the first range, it's always valid
  cmp currRange, ranges
  je .validRange

  ; if this range is empty (start > end), it's invalid
  cmp [currRange + 0], rax
  ja .invalidRange

  ; if this range is contained in another, it's invalid
  mov rdi, ranges
.checkContainedInLoop:

  mov rax, [currRange + 0]
  cmp rax, [rdi + 0]
  jb .notContained
  mov rax, [currRange + 8]
  cmp rax, [rdi + 8]
  ja .notContained

  jmp .invalidRange

.notContained:
  add rdi, 16

  cmp rdi, currRange
  jb .checkContainedInLoop

  ; replace all ranges contained in this with tombstone (fullptr, 0)
  mov rdi, ranges
.checkContainsLoop:

  mov rax, [currRange + 0]
  cmp rax, [rdi + 0]
  ja .notContains
  mov rax, [currRange + 8]
  cmp rax, [rdi + 8]
  jb .notContains

  mov rax, 0xffffffffffffffff
  mov [rdi + 0], rax
  mov rax, 0
  mov [rdi + 8], rax

.notContains:
  add rdi, 16

  cmp rdi, currRange
  jb .checkContainsLoop

.validRange:
  add currRange, 16

.invalidRange:
  cmp BYTE [currChar], `\n`
  jne .loadRangeLoop

  ; for each valid range (between ranges and currRange exclusive)
  ; count up the size
  mov accumulator, 0
.sumLoop:

  mov rax, [ranges + 8]
  test rax, rax
  jz .skip
  sub rax, [ranges + 0]
  inc rax
  add accumulator, rax

.skip:
  add ranges, 16

  cmp ranges, currRange
  jb .sumLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit