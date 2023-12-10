extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define x r12
%define y r13
%define SIZE 256 - 2
%define CELL 8
%define ROW CELL * (SIZE + 2)
%define TODO_ENTRY 24
%define todoHead rbp
%define todoTail rbx
%define OUTSIDE 0b10000000
%define VISITED 0b01000000
%define START   0b00100000
%define VALID   0b00010000
%define NORTH   0b00001000
%define SOUTH   0b00000100
%define EAST    0b00000010
%define WEST    0b00000001
%define startX [rsp + 0]
%define startY [rsp + 8]
%define accumulator r15
%define isInside r14b

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0 = eof/startX
  ;; rsp + 8 = startY

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; get input

  ; do-while curr < eof
  mov x, CELL
  mov y, ROW
.readLoop:

  ; read character
  mov al, [curr]
  movzx rax, al

  cmp rax, '|'
  jne .notNS

  mov QWORD [map + x + y], VALID | NORTH | SOUTH

  jmp .doneCategorizing
.notNS:

  cmp rax, '-'
  jne .notEW

  mov QWORD [map + x + y], VALID | EAST | WEST

  jmp .doneCategorizing
.notEW:

  cmp rax, 'L'
  jne .notNE

  mov QWORD [map + x + y], VALID | NORTH | EAST

  jmp .doneCategorizing
.notNE:

  cmp rax, 'J'
  jne .notNW

  mov QWORD [map + x + y], VALID | NORTH | WEST

  jmp .doneCategorizing
.notNW:

  cmp rax, '7'
  jne .notSW

  mov QWORD [map + x + y], VALID | SOUTH | WEST

  jmp .doneCategorizing
.notSW:

  cmp rax, 'F'
  jne .notSE

  mov QWORD [map + x + y], VALID | SOUTH | EAST

  jmp .doneCategorizing
.notSE:

  cmp rax, '.'
  jne .notGround

  mov QWORD [map + x + y], VALID

  jmp .doneCategorizing
.notGround:

  cmp rax, 'S'
  jne .notStart

  mov QWORD [map + x + y], VALID | START

  jmp .doneCategorizing
.notStart:

.doneCategorizing:
  add x, CELL
  inc curr

  ; skip line if newline
  cmp al, 0xa
  jne .notNewline

  mov x, CELL
  add y, ROW

.notNewline:

  cmp curr, eof
  jb .readLoop

  ; find start node

  ; while map[y][x].pipe != 'S'
  mov x, CELL
  mov y, ROW
.findStartLoop:
  test QWORD [map + x + y], START
  jnz .endFindStartLoop

  add x, CELL
  test QWORD [map + x + y], VALID
  jnz .notEndOfRow

  mov x, CELL
  add y, ROW

.notEndOfRow:

  jmp .findStartLoop
.endFindStartLoop:

  mov startX, x
  mov startY, y

  ; deduce start node connections

  test QWORD [map + x + y - ROW + 0], SOUTH
  jz .deduceStartNotNorth

  or QWORD [map + x + y], NORTH

.deduceStartNotNorth:

  test QWORD [map + x + y + ROW + 0], NORTH
  jz .deduceStartNotSouth

  or QWORD [map + x + y], SOUTH

.deduceStartNotSouth:

  test QWORD [map + x + y - CELL + 0], EAST
  jz .deduceStartNotWest

  or QWORD [map + x + y], WEST

.deduceStartNotWest:

  test QWORD [map + x + y + CELL + 0], WEST
  jz .deduceStartNotEast

  or QWORD [map + x + y], EAST

.deduceStartNotEast:

  ; set up initial todo list entry
  mov rdi, TODO_ENTRY
  call alloc
  mov todoHead, rax
  mov todoTail, rax

  mov [todoHead + 0], x
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], 0

  ; mark cells on the loop

  ; do-while todoHead != NULL
.traverseLoop:

  ; extract entry
  mov x, [todoHead + 0]
  mov y, [todoHead + 8]

  ; is this a valid cell - yes, always
  ; test QWORD [map + x + y], VALID
  ; jz .continueTraverseLoop

  ; consider cell to visit - have we been here before
  test QWORD [map + x + y], VISITED
  jnz .continueTraverseLoop ; skip if so

  ; mark as visited
  or QWORD [map + x + y], VISITED

  ; add neighbours
  test QWORD [map + x + y], NORTH
  jz .traverseAddNeighboursNotNorth

  ; add northern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 16], rax
  mov todoTail, rax
  mov [todoTail + 0], x
  mov [todoTail + 8], y
  sub QWORD [todoTail + 8], ROW
  mov QWORD [todoTail + 16], 0

.traverseAddNeighboursNotNorth:

  test QWORD [map + x + y], SOUTH
  jz .traverseAddNeighboursNotSouth

  ; add southern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 16], rax
  mov todoTail, rax
  mov [todoTail + 0], x
  mov [todoTail + 8], y
  add QWORD [todoTail + 8], ROW
  mov QWORD [todoTail + 16], 0

.traverseAddNeighboursNotSouth:

  test QWORD [map + x + y], EAST
  jz .traverseAddNeighboursNotEast

  ; add eastern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 16], rax
  mov todoTail, rax
  mov [todoTail + 0], x
  add QWORD [todoTail + 0], CELL
  mov [todoTail + 8], y
  mov QWORD [todoTail + 16], 0

.traverseAddNeighboursNotEast:

  test QWORD [map + x + y], WEST
  jz .traverseAddNeighboursNotWest

  ; add western neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 16], rax
  mov todoTail, rax
  mov [todoTail + 0], x
  sub QWORD [todoTail + 0], CELL
  mov [todoTail + 8], y
  mov QWORD [todoTail + 16], 0

.traverseAddNeighboursNotWest:

.continueTraverseLoop:

  mov todoHead, [todoHead + 16]

  test todoHead, todoHead
  jnz .traverseLoop

  ; count number of inside cells
  mov x, CELL
  mov y, ROW
  mov accumulator, 0

  ; for each row
.countRowLoop:

  mov isInside, 0

  ; for each cell
.countCellLoop:

  ; if current cell is part of the loop and goes north, flip isInside
  test QWORD [map + x + y], VISITED
  jz .countCellNotVisited
  test QWORD [map + x + y], NORTH
  jz .continueCountCellLoop

  not isInside

  jmp .continueCountCellLoop
.countCellNotVisited:

  ; if current cell is not part of the loop, and isInside, increment accumulator
  test isInside, isInside
  jz .continueCountCellLoop

  inc accumulator

.continueCountCellLoop:

  add x, CELL

  test QWORD [map + x + y], VALID
  jnz .countCellLoop

  mov x, CELL
  add y, ROW

  test QWORD [map + x + y], VALID
  jnz .countRowLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
;; struct MapCell {
;;   qword pipe; // bitfield = 0bOISVNSEW: O = outside, I = visited, S = start, V = valid, N = north, S = south, E = east, W = west
;;   qword distance; // distance from start node
;; }
map: resq CELL * (SIZE + 2) * (SIZE + 2)
;; struct TodoEntry {
;;   qword x;
;;   qword y;
;;   qword nextEntry;
;; }