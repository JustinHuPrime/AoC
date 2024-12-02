extern exit, mmap, findws, atol, skipws, putlong, newline, qsort

section .text

%define endOfFile r12
%define currChar r13
%define currReport r14
%define currNum r15
%define accumulator rbx
%define toRemove r15

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
.checkReportLoop:

  ; copy into scratch space with each element removed
  mov toRemove, currReport
.checkDampenerLoop:

  ; zero out scratch buffer
  mov rax, 0
  mov rcx, 16
  mov rdi, scratchBuffer
  rep stosq

  ; copy everything into scratch except what toRemove points at
  mov rsi, currReport
  mov rdi, scratchBuffer
.copyLoop:

  cmp rsi, toRemove
  je .continueCopyLoop

  mov rax, [rsi]
  mov [rdi], rax
  add rdi, 8

.continueCopyLoop:

  add rsi, 8
  cmp QWORD [rsi], 0
  jne .copyLoop

  ; check if it passes
  mov rdi, scratchBuffer
  call checkReport
  add accumulator, rax
  test rax, rax
  jnz .endCheckDampenerLoop

  add toRemove, 8

  cmp QWORD [toRemove], 0
  jne .checkDampenerLoop
.endCheckDampenerLoop:

  add currReport, 8 * 16

  cmp QWORD [currReport], 0
  jne .checkReportLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; Checks for report validity
;; check that the next element is either +1, 2, 3 or -1, 2, 3 from this
;; or the next element is zero
;; also check that the direction of the difference is consistent with direction (or it's also unset)
;; rdi = pointer to start of report to check
;; returns: 1 if report is safe, 0 otherwise
checkReport:
  mov rax, 1 ; rax = return value
  mov rdx, 0 ; rdx = direction
  mov rcx, 0 ; rcx = zero constant
.checkElementLoop:

  mov r8, [rdi] ; r8 = current
  mov rsi, [rdi + 8] ; rsi = next

  ; is next element zero, if so, break
  test rsi, rsi
  je .endCheckElementLoop

  sub r8, rsi ; r8 = difference

  ; check for direction consistency
  test rdx, rdx
  jnz .directionNotZero

  ; direction is zero; set it according to r8
  mov rdx, r8
  jmp .endDirectionCheck

.directionNotZero:
  jns .directionNotNegative

  ; direction is negative; r8 must also be negative
  test r8, r8
  js .endDirectionCheck

  mov rax, 0
  jmp .endCheckElementLoop

.directionNotNegative:

  ; direction has to be positive; r8 must also be positive
  test r8, r8
  jg .endDirectionCheck

  mov rax, 0
  jmp .endCheckElementLoop

.endDirectionCheck:

  mov rsi, r8 ; rsi = -difference
  neg rsi
  test r8, r8 ; do absolute value
  cmovs r8, rsi ; r8 = absolute value of difference

  test r8, r8 ; check - difference is not zero
  cmove rax, rcx
  je .endCheckElementLoop

  cmp r8, 3 ; check - difference is not more than 3
  cmovg rax, rcx
  jg .endCheckElementLoop

  add rdi, 8

  jmp .checkElementLoop
.endCheckElementLoop:

  ret

section .bss

reports:
  resq 16 * 1024
scratchBuffer:
  resq 16