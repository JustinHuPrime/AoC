extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile r13
%define accumulator r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; do-while currChar < endOfFile
  mov accumulator, 0
.loop:

  ; do-while rcx >= 0
  mov rcx, 11 ; rcx = number of digits left (excluding this one)
  mov rax, 0 ; rax = this-row accumulator
.digitLoop:

  ; find the largest digit, excluding the last rcx
  mov rsi, currChar
  mov rdi, rsi ; rdi = pointer to largest so far
.findLargestLoop:

  mov r8b, [rsi]
  cmp r8b, [rdi]
  cmova rdi, rsi

  inc rsi

  cmp BYTE [rsi + rcx], `\n`
  jne .findLargestLoop

  ; move search area forward
  lea currChar, [rdi + 1]

  ; push digit to this-row accumulator
  mov rdx, 10
  mul rdx
  movzx rdi, BYTE [rdi]
  sub rdi, '0'
  add rax, rdi

  dec rcx
  jns .digitLoop

  ; done with this line
  lea currChar, [rsi + 1]

  add accumulator, rax

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit