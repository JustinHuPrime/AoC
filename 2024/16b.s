extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currCell r13

%define startCell r14
%define endCell r15

%define curr r12
%define todoHead r13
%define direction rbx
%define score rbp

%define accumulator r12

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

  ; read map
  mov currCell, 0
.readLoop:

.readLineLoop:
  mov al, [currChar]
  mov [map + 1 * currCell], al

  cmp al, 'S'
  cmove startCell, currCell
  cmp al, 'E'
  cmove endCell, currCell

  inc currCell
  inc currChar

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  and currCell, ~255
  add currCell, 256
  inc currChar

  cmp currChar, endOfFile
  jb .readLoop

  ; set up todo and visited
  mov todoHead, todo
  mov [todoHead + 0 * 8], startCell
  mov QWORD [todoHead + 1 * 8], 1
  mov QWORD [todoHead + 2 * 8], 0
  add todoHead, 3 * 8

  mov rax, -1
  mov rdi, visited
  mov rcx, 4 * 256 * 256
  rep stosq

  ;; as while-loop form of tail-recursive genrec graph traversal with todo and combined visited/rsf accumulator
.traverseLoop:
  sub todoHead, 3 * 8
  mov curr, [todoHead + 0 * 8]
  mov direction, [todoHead + 1 * 8]
  mov score, [todoHead + 2 * 8]

  ; is this even a valid cell
  cmp BYTE [map + curr], '#'
  je .continueTraverseLoop ; no, bail

  ; have we visited here, facing this direction, for less than the current score costs
  mov rdi, direction
  call directionToOffset

  cmp [visited + rax + curr * 8], score
  jb .continueTraverseLoop ; we've been in this exact situation for cheaper, bail

  mov [visited + rax + curr * 8], score ; note down that we got here for this much

  ; move around
  
  ; forward
  mov rax, direction
  add rax, curr
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], direction
  mov rax, score
  add rax, 1 ; moved one space, no turning
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

  ; left
  mov rdi, direction
  call turnLeft
  mov rdi, rax
  add rax, curr
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rdi
  mov rax, score
  add rax, 1001 ; moved one space and turned 90 degrees
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

  ; right
  mov rdi, direction
  call turnRight
  mov rdi, rax
  add rax, curr
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rdi
  mov rax, score
  add rax, 1001
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

  ; backwards - never cheaper
  ; mov rdi, direction
  ; neg rdi
  ; mov rax, rdi
  ; add rax, curr
  ; mov [todoHead + 0 * 8], rax
  ; mov [todoHead + 1 * 8], rdi
  ; mov rax, score
  ; add rax, 2001 ; turned around and moved one space
  ; mov [todoHead + 2 * 8], rax
  ; add todoHead, 3 * 8

.continueTraverseLoop:

  cmp todoHead, todo
  ja .traverseLoop

  mov accumulator, [visited + (0 * 256 * 256 * 8) + 8 * endCell]
  mov rax, [visited + (1 * 256 * 256 * 8) + 8 * endCell]
  cmp rax, accumulator
  cmovb accumulator, rax
  mov rax, [visited + (2 * 256 * 256 * 8) + 8 * endCell]
  cmp rax, accumulator
  cmovb accumulator, rax
  mov rax, [visited + (3 * 256 * 256 * 8) + 8 * endCell]
  cmp rax, accumulator
  cmovb accumulator, rax

  ;; as while-loop form of tail-recursive genrec graph traversal with todo, implicit visited, and rsf accumulator
  mov todoHead, todo
  mov [todoHead + 0 * 8], endCell
  mov QWORD [todoHead + 1 * 8], -256
  mov [todoHead + 2 * 8], accumulator
  add todoHead, 3 * 8
  
  mov [todoHead + 0 * 8], endCell
  mov QWORD [todoHead + 1 * 8], 1
  mov [todoHead + 2 * 8], accumulator
  add todoHead, 3 * 8
  
  mov [todoHead + 0 * 8], endCell
  mov QWORD [todoHead + 1 * 8], 256
  mov [todoHead + 2 * 8], accumulator
  add todoHead, 3 * 8
  
  mov [todoHead + 0 * 8], endCell
  mov QWORD [todoHead + 1 * 8], -1
  mov [todoHead + 2 * 8], accumulator
  add todoHead, 3 * 8

.pathLoop:
  sub todoHead, 3 * 8
  mov curr, [todoHead + 0 * 8]
  mov direction, [todoHead + 1 * 8]
  mov score, [todoHead + 2 * 8]

  ; did we have this score when we visited here, facing this direction?
  mov rdi, direction
  call directionToOffset

  cmp [visited + rax + curr * 8], score
  jne .continuePathLoop ; not part of any optimal path

  mov BYTE [optimal + curr], 1 ; note that this is part of the optimal path

  ; consider next steps
  cmp score, 0
  je .continuePathLoop ; unless we're out of score

  ; backward
  mov rax, curr
  sub rax, direction
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], direction
  mov rax, score
  sub rax, 1
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

  ; left
  mov rax, curr
  sub rax, direction
  mov [todoHead + 0 * 8], rax
  mov rdi, direction
  call turnRight
  mov [todoHead + 1 * 8], rax
  mov rax, score
  sub rax, 1001
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

  ; right
  mov rax, curr
  sub rax, direction
  mov [todoHead + 0 * 8], rax
  mov rdi, direction
  call turnLeft
  mov [todoHead + 1 * 8], rax
  mov rax, score
  sub rax, 1001
  mov [todoHead + 2 * 8], rax
  add todoHead, 3 * 8

.continuePathLoop:

  cmp todoHead, todo
  ja .pathLoop

  mov rcx, 0
  mov accumulator, 0
.countLoop:

  movzx rax, BYTE [optimal + rcx]
  add accumulator, rax
  inc rcx

  cmp rcx, 256 * 256
  jb .countLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = direction
;; returns direction as visited array offset (north = 0 * 256 * 256 * 8, east = 1 * 256 * 256 * 8, south = 2 * 256 * 256 * 8, west = 3 * 256 * 256 * 8)
;; noclobber
directionToOffset:
  mov rax, 0 * 256 * 256 * 8
  cmp rdi, -256
  jne .notNorth

  ret

.notNorth:
  mov rax, 1 * 256 * 256 * 8
  cmp rdi, 1
  jne .notEast

  ret
  
.notEast:
  mov rax, 2 * 256 * 256 * 8
  cmp rdi, 256
  jne .notSouth

  ret
  
.notSouth:
  mov rax, 3 * 256 * 256 * 8
  ret

;; rdi = direction
;; turns left
;; noclobber
turnLeft:
  mov rax, -1
  cmp rdi, -256
  jne .notNorth

  ret

.notNorth:
  mov rax, -256
  cmp rdi, 1
  jne .notEast

  ret
  
.notEast:
  mov rax, 1
  cmp rdi, 256
  jne .notSouth

  ret
  
.notSouth:
  mov rax, 256
  ret

;; rdi = direction
;; turns right
;; noclobber
turnRight:
  mov rax, 1
  cmp rdi, -256
  jne .notNorth

  ret

.notNorth:
  mov rax, 256
  cmp rdi, 1
  jne .notEast

  ret
  
.notEast:
  mov rax, -1
  cmp rdi, 256
  jne .notSouth

  ret
  
.notSouth:
  mov rax, -256
  ret

section .bss
map: resb 256 * 256
optimal: resb 256 * 256
visited: resq 4 * 256 * 256
;; struct visited {
;;   qword[256][256] north, east, south, west; // score obtained when we got to this place
;; }
todo: resq 3 * 256 * 256 * 4
;; struct todo {
;;   unsigned qword cell; // as offset into map
;;   signed qword direction; // as array offset
;;   unsigned qword score; // score needed to end up here
;; }
