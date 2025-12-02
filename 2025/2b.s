extern exit, mmap, atol, putlong, newline, sputlong, findnotnum, puts

section .text

%define currChar r12
%define endOfFile r13
%define accumulator r15
%define currValue r14
%define endValue rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
  mov accumulator, 0
.loop:
  ; parse the start of the range
  mov rdi, currChar
  call findnotnum

  mov rdi, currChar
  mov rsi, rax
  lea currChar, [rax + 1]
  call atol

  mov currValue, rax

  ; parse the end of the range
  mov rdi, currChar
  call findnotnum

  mov rdi, currChar
  mov rsi, rax
  lea currChar, [rax + 1]
  call atol

  mov endValue, rax

  ; for all values from currValue to endValue inclusive
.innerLoop:
  ; print out the value
  mov rdi, currValue
  mov rsi, buffer
  call sputlong

  ; sequence consists of repeats `n` long if
  ; - the `n` characters starting at `mn`, for `m` in Z are the same
  ; - `mn` == length for some `m`
  ; for any `n` from 1 to length.floor_div(2) inclusive
  mov r8, 1 ; r8 = n
  mov r9, rdx
  sub r9, rax
  shr r9, 1 ; r9 = length / 2
.checkRepeatsForN:
  cmp r8, r9
  ja .continueInnerLoop

  ; while `mn` < length and `(m + 1) <= length`
  lea rdi, [rax + r8] ; rdi = `mn`
.checkRepeatsOverLength:
  cmp rdi, rdx
  je .hasRepeats ; we would start exactly at the length - is a repeat

  lea rsi, [rdi + r8]
  cmp rsi, rdx
  ja .endCheckRepeatsOverLength ; if we would overflow length, then this can't fit evenly - not repeating

  ; check that this section repeats
  mov rcx, r8
  mov rsi, rax
  ; mov rdi, rdi
.compareLoop:
  cmpsb
  loope .compareLoop
  jne .endCheckRepeatsOverLength ; sections unequal, bail

  jmp .checkRepeatsOverLength
.endCheckRepeatsOverLength:

  inc r8

  jmp .checkRepeatsForN
.hasRepeats:

  ; had repeats - this is invalid
  add accumulator, currValue

.continueInnerLoop:

  inc currValue

  cmp currValue, endValue
  jbe .innerLoop

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
buffer: resb 20
