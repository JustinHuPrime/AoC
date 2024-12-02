extern exit, mmap, findws, atol, skipws, putlong, newline, qsort

section .text

%define endOfFile r12
%define currChar r13
%define currReport r14
%define currNum r15
%define accumulator rbx
%define direction r13
%define safe r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; read data
  mov currReport, reports
  mov currNum, reports
.readLineLoop:

  ; each line consists of some number of elements
.readElementLoop:

  mov rdi, currChar
  call findws

  mov rdi, currChar
  mov currChar, rax
  mov rsi, rax
  call atol

  mov [currNum], rax

  inc currChar ; skip whitespace
  add currNum, 8 ; next number

  cmp BYTE [currChar - 1], 0xa ; \n
  jne .readElementLoop

  ; move to next report line
  add currReport, 8 * 16
  mov currNum, currReport

  cmp currChar, endOfFile
  jb .readLineLoop

  ; for each report, how many are valid?
  mov accumulator, 0
  mov currReport, reports
  mov currNum, reports
  mov rbp, 0 ; rbp = zero constant
.checkReportLoop:

  ; check that the next element is either +1, 2, 3 or -1, 2, 3 from this
  ; or the next element is zero
  ; also check that the direction of the difference is consistent with direction (or it's also unset)
  mov safe, 1
  mov direction, 0
.checkElementLoop:

  mov rdi, [currNum] ; rdi = current
  mov rsi, [currNum + 8] ; rsi = next

  ; is next element zero, if so, break
  test rsi, rsi
  je .endCheckElementLoop

  sub rdi, rsi ; rdi = difference

  ; check for direction consistency
  test direction, direction
  jnz .directionNotZero

  ; direction is zero; set it according to rdi
  mov direction, rdi
  jmp .endDirectionCheck

.directionNotZero:
  jns .directionNotNegative

  ; direction is negative; rdi must also be negative
  test rdi, rdi
  js .endDirectionCheck

  mov safe, rbp
  jmp .endCheckElementLoop

.directionNotNegative:

  ; direction has to be positive; rdi must also be positive
  test rdi, rdi
  jg .endDirectionCheck

  mov safe, rbp
  jmp .endCheckElementLoop

.endDirectionCheck:

  mov rsi, rdi ; rsi = -difference
  neg rsi
  test rdi, rdi ; do absolute value
  cmovs rdi, rsi ; rdi = absolute value of difference

  test rdi, rdi ; check - difference is not zero
  cmove safe, rbp
  je .endCheckElementLoop

  cmp rdi, 3 ; check - difference is not more than 3
  cmovg safe, rbp
  jg .endCheckElementLoop

  add currNum, 8

  jmp .checkElementLoop
.endCheckElementLoop:

  add accumulator, safe

  add currReport, 8 * 16
  mov currNum, currReport

  cmp QWORD [currReport], 0
  jne .checkReportLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

reports:
  resq 16 * 1024