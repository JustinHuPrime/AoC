extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define currLine r13
%define currCol r14
%define curr r12
%define todoTop r13
%define accumulator r14
; %define visitedLen r15
%define currTrailhead rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov currLine, map + 64 + 1
.readLoop:

  mov currCol, currLine
.readLineLoop:

  mov al, [currChar]
  mov [currCol], al

  inc currChar
  inc currCol

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  add currLine, 64

  cmp currChar, endOfFile
  jb .readLoop

  mov accumulator, 0
  
  ; for each trailhead
  ; initialize todo list
  mov currTrailhead, map
.findTrailheadsLoop:

  cmp BYTE [currTrailhead], '0'
  jne .continueFindTrailheadsLoop

  mov todoTop, todoList + 8
  mov [todoList], currTrailhead

  ;; location -> number
  ;; find how many 9s can be reached from this location

  ;; template as while-loop-tail-recursive genrec graph traversal with visited, rsf, todo list accumulators

  ; while todo list is not empty
  ; mov visitedLen, 0
.traverseLoop:

  ; pop current
  sub todoTop, 8
  mov curr, [todoTop]

  ; ; have we visited this before
  ; mov rdi, visitedList
  ; mov rax, curr
  ; mov rcx, visitedLen
  ; repne scasq
  ; je .continueTraverseLoop ; yes, done with this element

  ; mov [visitedList + 8 * visitedLen], curr
  ; inc visitedLen

  ; base case - this is a 9
  cmp BYTE [curr], '9'
  jne .notNine

  ; add to accumulator, done with this element
  inc accumulator
  jmp .continueTraverseLoop

.notNine:

  ; add neighbours if neighbour - current == 1
  lea rax, [curr - 64]
  mov dl, [rax]
  sub dl, [curr]
  cmp dl, 1
  jne .notDown

  mov [todoTop], rax
  add todoTop, 8

.notDown:
  lea rax, [curr + 64]
  mov dl, [rax]
  sub dl, [curr]
  cmp dl, 1
  jne .notUp

  mov [todoTop], rax
  add todoTop, 8

.notUp:
  lea rax, [curr - 1]
  mov dl, [rax]
  sub dl, [curr]
  cmp dl, 1
  jne .notLeft

  mov [todoTop], rax
  add todoTop, 8

.notLeft:
  lea rax, [curr + 1]
  mov dl, [rax]
  sub dl, [curr]
  cmp dl, 1
  jne .continueTraverseLoop

  mov [todoTop], rax
  add todoTop, 8

.continueTraverseLoop:

  cmp todoTop, todoList
  ja .traverseLoop

.continueFindTrailheadsLoop:

  inc currTrailhead

  cmp currTrailhead, map + 64 * 64
  jb .findTrailheadsLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
map: resb 64 * 64
todoList: resq 64 * 64
; visitedList: resq 64 * 64
