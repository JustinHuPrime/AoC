extern mmap, putlong, newline, exit, countc, alloc, findnotnum, atol, skipws

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define numRows r13
%define numCols r14
%define table r15
%define offset rbx
%define currEntry r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0, endOfFile

  mov currChar, rax
  lea rdx, [rax + rdx]
  mov endOfFile, rdx

  ; count number of rows of numbers (= number of newlines - 1)
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, `\n`
  call countc
  lea numRows, [rax - 1]

  ; count number of columns of numbers (= number of * characters + number of + characters)
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, '*'
  call countc
  mov numCols, rax
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, '+'
  call countc
  add numCols, rax

  ; allocate
  mov rax, numRows
  mul numCols
  lea rdi, [rax * 8]
  call alloc
  mov table, rax

  ; read input
  mov offset, 0
.readLoop:

  ; read a row
  lea currEntry, [table + offset * 8]
.readRow:

  ; read a number
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov currChar, rax
  mov rsi, rax
  call atol ; rax = number

  ; store it
  mov [currEntry], rax
  lea currEntry, [currEntry + numRows * 8]

  ; move to next number, if any
.skipSpaces:
  cmp BYTE [currChar], ' '
  jne .endSkipSpaces
  inc currChar
  jmp .skipSpaces
.endSkipSpaces:

  cmp BYTE [currChar], `\n`
  jne .readRow

  inc offset
  mov rdi, currChar
  call skipws
  mov currChar, rax

  cmp offset, numRows
  jb .readLoop

  ; do the operation requested
  mov rdi, 0 ; rdi = grand total accumulator
  mov currEntry, table
.operateLoop:
  cmp BYTE [currChar], '+'
  jne .notPlus

  mov rax, 0 ; rax = entry accumulator
  mov offset, 0
.addLoop:

  add rax, [currEntry + offset * 8]
  inc offset

  cmp offset, numRows
  jb .addLoop

  add rdi, rax

  inc currChar
  lea currEntry, [currEntry + numRows * 8]
  jmp .operateLoop

.notPlus:
  cmp BYTE [currChar], '*'
  jne .notTimes

  mov rax, 1 ; rax = entry accumulator
  mov offset, 0
.mulLoop:

  mul QWORD [currEntry + offset * 8]
  inc offset

  cmp offset, numRows
  jb .mulLoop

  add rdi, rax

  inc currChar
  lea currEntry, [currEntry + numRows * 8]
  jmp .operateLoop

.notTimes:
  cmp BYTE [currChar], ' '
  jne .notSpace

  inc currChar
  jmp .operateLoop

.notSpace:

  ; mov rdi, rdi
  call putlong
  call newline

  mov dil, 0
  call exit