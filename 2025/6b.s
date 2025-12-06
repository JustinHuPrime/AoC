extern mmap, putlong, newline, exit, countc, alloc, findnl

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define numRows r13
%define currOp r14
%define buffer r15
%define lineLength rbx
%define accumulator rbp
%define numEntries r13

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

  ; find length of a line (how many characters forward to go to get to the next one down)
  mov rdi, currChar
  call findnl
  sub rax, currChar
  lea lineLength, [rax + 1]

  ; make pointer to operation track
  mov rax, numRows
  mul lineLength
  lea currOp, [currChar + rax]

  ; process operations
  mov accumulator, 0
  mov r10, 10
.loop:

  ; find the start of the next problem
  mov r8, currChar
  mov r9, currOp
.findNextLoop:
  inc r8
  inc r9
  cmp BYTE [r9], ' '
  je .findNextLoop

  ; move back one to point at the padding
  cmp BYTE [r9], `\n`
  je .skipBack
  dec r8
  dec r9
.skipBack:

  ; allocate the buffer
  mov rdi, r9
  sub rdi, currOp
  mov numEntries, rdi
  shl rdi, 3
  call alloc
  mov buffer, rax

  ; parse into the buffer
  mov rdi, buffer
.parseLoop:

  mov rsi, currChar
  mov rax, 0
.parseColLoop:

  ; if current character is a space, do nothing to rax
  cmp BYTE [rsi], ' '
  je .continueParseColLoop

  ; else, rax = rax * 10 + char - '0'
  mul r10
  mov dl, [rsi]
  sub dl, '0'
  movzx rdx, dl
  add rax, rdx

.continueParseColLoop:
  add rsi, lineLength

  cmp rsi, currOp
  jb .parseColLoop

  mov [rdi], rax
  add rdi, 8

  inc currChar

  cmp currChar, r8
  jb .parseLoop

  ; operate on the buffer
  mov rdi, 0
  cmp BYTE [currOp], '*'
  jne .addOp

  mov rax, 1
.mulLoop:
  mul QWORD [buffer + rdi * 8]
  inc rdi
  cmp rdi, numEntries
  jb .mulLoop

  jmp .doneOp
.addOp:

  mov rax, 0
.addLoop:
  add rax, [buffer + rdi * 8]
  inc rdi
  cmp rdi, numEntries
  jb .addLoop

.doneOp:
  add accumulator, rax

  cmp BYTE [r9], `\n`
  je .endLoop

  lea currChar, [r8 + 1]
  lea currOp, [r9 + 1]
  
  jmp .loop
.endLoop:

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit