extern exit, mmap, putlong, newline, alloc, findws, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define currLine r13
%define currCol r14

%define curr r12
%define todoHead r13
%define accumulator r14
%define currType r15b
%define perimeter rbx
%define area rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  ; read file
  mov currLine, map + 256 + 1
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
  add currLine, 256

  cmp currChar, endOfFile
  jb .readLoop

  ; for each cell
  mov curr, 256 + 1
  mov accumulator, 0
.scanLoop:

  cmp BYTE [map + curr], 0 ; not valid cell
  je .continueScanLoop
  cmp BYTE [visited + curr], 1 ; visited
  je .continueScanLoop

  ; valid cell that's not visited - do flood fill
  ;; while-loop-tail-recursive graph traversal with todo list, visited, and rsf accumulator
  mov todoHead, todo
  mov [todoHead], curr
  add todoHead, 8

  mov currType, [map + curr]
  
  mov perimeter, 0
  
  mov area, 0
.traverseLoop:
  sub todoHead, 8
  mov rax, [todoHead]

  ; if already visited, skip
  cmp BYTE [visited + rax], 1
  je .continueTraverseLoop

  ; mark as visited
  mov BYTE [visited + rax], 1
  ; add to area
  inc area

  ; assume all neighbours are different
  add perimeter, 4

  ; check each neighbour
  cmp [map + rax - 256], currType
  jne .doneUp

  dec perimeter

  cmp BYTE [visited + rax - 256], 1
  je .doneUp

  lea rdx, [rax - 256]
  mov [todoHead], rdx
  add todoHead, 8

.doneUp:
  cmp [map + rax + 256], currType
  jne .doneDown

  dec perimeter

  cmp BYTE [visited + rax + 256], 1
  je .doneDown

  lea rdx, [rax + 256]
  mov [todoHead], rdx
  add todoHead, 8

.doneDown:
  cmp [map + rax - 1], currType
  jne .doneLeft

  dec perimeter

  cmp BYTE [visited + rax - 1], 1
  je .doneLeft

  lea rdx, [rax - 1]
  mov [todoHead], rdx
  add todoHead, 8

.doneLeft:
  cmp [map + rax + 1], currType
  jne .doneRight

  dec perimeter

  cmp BYTE [visited + rax + 1], 1
  je .doneRight

  lea rdx, [rax + 1]
  mov [todoHead], rdx
  add todoHead, 8

.doneRight:
.continueTraverseLoop:

  cmp todoHead, todo
  ja .traverseLoop

  ; accumulator += area * perimeter
  mov rax, area
  mul perimeter
  add accumulator, rax

  ; mov rdi, rax
  ; call putlong
  ; call newline
  ; mov rdi, area
  ; call putlong
  ; call newline
  ; mov rdi, perimeter
  ; call putlong
  ; call newline
  ; call newline

.continueScanLoop:

  inc curr

  cmp curr, 256 * 256
  jb .scanLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

map: resb 256 * 256
visited: resb 256 * 256
todo: resq 256 * 256
