extern exit, mmap, putlong, newline, findnotnum, atol

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currLine r13

%define todoHead r12
%define curr r13
%define steps r14

%define mapSize 70
%define numEntries 1024
; %define mapSize 6
; %define numEntries 12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  ; initialize map with border
  mov rdi, map
  mov rax, '#'
  mov rcx, 128 * 128
  rep stosb

  mov rsi, 128
.initLoop:

  mov rdi, 1
.initLineLoop:

  mov BYTE [map + rsi + rdi], '.'

  inc rdi
  cmp rdi, mapSize + 1
  jbe .initLineLoop

  add rsi, 128
  cmp rsi, (mapSize + 1) * 128
  jbe .initLoop

  ; read first 1024 entries
  mov currLine, 0
.readLoop:

  ; x
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  inc rax ; account for padding
  mov r15, rax

  inc currChar ; skip ','

  ; y
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  inc rax ; account for padding
  shl rax, 7 ; rax *= 2**7
  add r15, rax

  ; mark
  mov BYTE [map + 1 * r15], '#'

  inc currChar
  inc currLine

  cmp currLine, numEntries
  jb .readLoop

  mov rax, -1
  mov rdi, visited
  mov rcx, 128 * 128
  rep stosq

  ;; template as while-loop-tail-recursive graph traversal with todo and combined visited/rsf accumulator
  mov todoHead, todo
  mov QWORD [todoHead + 0 * 8], 128 + 1
  mov QWORD [todoHead + 1 * 8], 0
  add todoHead, 2 * 8
.traverseLoop:

  sub todoHead, 2 * 8
  mov curr, [todoHead + 0 * 8]
  mov steps, [todoHead + 1 * 8]

  ; check - have we been here for equivalent or cheaper
  cmp steps, [visited + 8 * curr]
  jae .continueTraverseLoop

  ; record new, cheaper cost of getting here
  mov [visited + 8 * curr], steps

  ; consider moving around
  inc steps
  cmp BYTE [map + curr - 128], '#'
  je .notUp

  lea rax, [curr - 128]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notUp:
  cmp BYTE [map + curr + 128], '#'
  je .notDown

  lea rax, [curr + 128]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notDown:
  cmp BYTE [map + curr - 1], '#'
  je .notLeft

  lea rax, [curr - 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notLeft:
  cmp BYTE [map + curr + 1], '#'
  je .notRight

  lea rax, [curr + 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notRight:

.continueTraverseLoop:

  cmp todoHead, todo
  ja .traverseLoop

  mov rdi, [visited + 8 * ((mapSize + 1) * 128 + (mapSize + 1))]
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
map: resb 128 * 128
visited: resq 128 * 128
todo: resq 2 * 128 * 128
