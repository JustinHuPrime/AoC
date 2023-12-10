extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define x r12
%define y r13
%define SIZE 256 - 2
%define CELL 16
%define ROW CELL * (SIZE + 2)
%define TODO_ENTRY 32
%define todoHead rbp
%define todoTail rbx
%define distance r14
%define accumulator r15
%define START 0b100000
%define VALID 0b010000
%define NORTH 0b001000
%define SOUTH 0b000100
%define EAST  0b000010
%define WEST  0b000001

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof

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

  mov QWORD [map + x + y + 0], VALID | NORTH | SOUTH

  jmp .doneCategorizing
.notNS:

  cmp rax, '-'
  jne .notEW

  mov QWORD [map + x + y + 0], VALID | EAST | WEST

  jmp .doneCategorizing
.notEW:

  cmp rax, 'L'
  jne .notNE

  mov QWORD [map + x + y + 0], VALID | NORTH | EAST

  jmp .doneCategorizing
.notNE:

  cmp rax, 'J'
  jne .notNW

  mov QWORD [map + x + y + 0], VALID | NORTH | WEST

  jmp .doneCategorizing
.notNW:

  cmp rax, '7'
  jne .notSW

  mov QWORD [map + x + y + 0], VALID | SOUTH | WEST

  jmp .doneCategorizing
.notSW:

  cmp rax, 'F'
  jne .notSE

  mov QWORD [map + x + y + 0], VALID | SOUTH | EAST

  jmp .doneCategorizing
.notSE:

  cmp rax, '.'
  jne .notGround

  mov QWORD [map + x + y + 0], VALID

  jmp .doneCategorizing
.notGround:

  cmp rax, 'S'
  jne .notStart

  mov QWORD [map + x + y + 0], VALID | START

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
  test QWORD [map + x + y + 0], START
  jnz .endFindStartLoop

  add x, CELL
  test QWORD [map + x + y + 0], VALID
  jnz .notEndOfRow

  mov x, CELL
  add y, ROW

.notEndOfRow:

  jmp .findStartLoop
.endFindStartLoop:

  ; deduce start node connections

  test QWORD [map + x + y - ROW + 0], SOUTH
  jz .deduceStartNotNorth

  or QWORD [map + x + y + 0], NORTH

.deduceStartNotNorth:

  test QWORD [map + x + y + ROW + 0], NORTH
  jz .deduceStartNotSouth

  or QWORD [map + x + y + 0], SOUTH

.deduceStartNotSouth:

  test QWORD [map + x + y - CELL + 0], EAST
  jz .deduceStartNotWest

  or QWORD [map + x + y + 0], WEST

.deduceStartNotWest:

  test QWORD [map + x + y + CELL + 0], WEST
  jz .deduceStartNotEast

  or QWORD [map + x + y + 0], EAST

.deduceStartNotEast:

  ; set up initial todo list entry
  mov rdi, TODO_ENTRY
  call alloc
  mov todoHead, rax
  mov todoTail, rax

  mov QWORD [todoHead + 0], 1
  mov [todoHead + 8], x
  mov [todoHead + 16], y
  mov QWORD [todoHead + 24], 0

  ; do-while todoHead != NULL
  mov accumulator, 0
.traverseLoop:

  ; extract entry
  mov distance, [todoHead + 0]
  mov x, [todoHead + 8]
  mov y, [todoHead + 16]

  ; is this a valid cell - yes, always
  ; test QWORD [map + x + y + 0], VALID
  ; jz .continue

  ; consider cell to visit - have we been here before
  cmp QWORD [map + x + y + 8], 0
  jne .continue ; skip if so - they got here faster

  ; haven't visited - set distance, update accumulator
  mov [map + x + y + 8], distance
  cmp distance, accumulator
  cmova accumulator, distance

  ; add neighbours
  inc distance

  test QWORD [map + x + y + 0], NORTH
  jz .addNeighboursNotNorth

  ; add northern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax
  mov [todoTail + 0], distance
  mov [todoTail + 8], x
  mov [todoTail + 16], y
  sub QWORD [todoTail + 16], ROW
  mov QWORD [todoTail + 24], 0

.addNeighboursNotNorth:

  test QWORD [map + x + y + 0], SOUTH
  jz .addNeighboursNotSouth

  ; add southern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax
  mov [todoTail + 0], distance
  mov [todoTail + 8], x
  mov [todoTail + 16], y
  add QWORD [todoTail + 16], ROW
  mov QWORD [todoTail + 24], 0

.addNeighboursNotSouth:

  test QWORD [map + x + y + 0], EAST
  jz .addNeighboursNotEast

  ; add eastern neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax
  mov [todoTail + 0], distance
  mov [todoTail + 8], x
  add QWORD [todoTail + 8], CELL
  mov [todoTail + 16], y
  mov QWORD [todoTail + 24], 0

.addNeighboursNotEast:

  test QWORD [map + x + y + 0], WEST
  jz .addNeighboursNotWest

  ; add western neighbour
  mov rdi, TODO_ENTRY
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax
  mov [todoTail + 0], distance
  mov [todoTail + 8], x
  sub QWORD [todoTail + 8], CELL
  mov [todoTail + 16], y
  mov QWORD [todoTail + 24], 0

.addNeighboursNotWest:

.continue:

  mov todoHead, [todoHead + 24]

  test todoHead, todoHead
  jnz .traverseLoop

  dec accumulator ; adjust numbering - start had distance zero

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
;; struct MapCell {
;;   qword pipe; // bitfield = 0bSVNSEW: S = start, V = valid, N = north, S = south, E = east, W = west
;;   qword distance; // distance from start node
;; }
map: resq CELL * (SIZE + 2) * (SIZE + 2)
;; struct TodoEntry {
;;   qword distance;
;;   qword x;
;;   qword y;
;;   qword nextEntry;
;; }