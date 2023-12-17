extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define SIZE 256
%define x rbp
%define y r12
%define offset rbx
%define todoHead rbp
%define todoTail r12
%define NORTH 0b1000
%define SOUTH 0b0100
%define EAST  0b0010
%define WEST  0b0001
%define TODO_ENTRY_SIZE 4 * 8
%define cost r13
%define lastDirection r14b
%define momentumCounter r15b
%define targetOffset [rsp + 0]

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof/targetOffset

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; read map
  mov y, SIZE
.readMapLoop:

  mov x, 1
.readMapLineLoop:

  mov al, [curr]
  sub al, '0'
  mov [map + x + y], al

  inc curr
  inc x

  cmp BYTE [curr], `\n`
  jne .readMapLineLoop

  inc curr ; skip newline
  add y, SIZE

  cmp curr, eof
  jb .readMapLoop

  lea rax, [y - SIZE]
  add rax, x
  dec rax
  mov targetOffset, rax

  ; do graph traversal

  mov rdi, costs
  mov rax, -1
  mov rcx, SIZE * SIZE
  rep stosq

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov todoHead, rax
  mov todoTail, rax

  mov QWORD [todoHead + 0], SIZE + 1
  mov QWORD [todoHead + 8], 0
  mov BYTE [todoHead + 16], 0
  mov BYTE [todoHead + 17], 0
  mov QWORD [todoHead + 24], 0

.traverseLoop:

  ; unpack entry
  mov offset, [todoHead + 0]
  mov cost, [todoHead + 8]
  mov lastDirection, [todoHead + 16]
  mov momentumCounter, [todoHead + 17]

  ; check - is this even a valid space?
  ; stop if so
  cmp BYTE [map + offset], 0
  je .continueTraverseLoop

  ; check - has someone else gotten here cheaper?
  ; note - if we've gotten here for the same price, we might have a better momentum vector
  cmp [costs + offset * 8], cost
  jb .continueTraverseLoop

  ; store cost to get here
  mov [costs + offset * 8], cost

  ; check - are we at the target?
  ; stop if so
  cmp offset, targetOffset
  je .continueTraverseLoop

  ; continue traversing

  ; try going north
  test lastDirection, SOUTH
  jnz .notNorth
  test lastDirection, NORTH
  jz .notNorthMomentum
  cmp momentumCounter, 3
  jae .notNorth
.notNorthMomentum:

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax

  lea rax, [offset - SIZE]
  mov [todoTail + 0], rax
  
  movzx rax, BYTE [map + offset - SIZE]
  add rax, cost
  mov [todoTail + 8], rax
  
  mov BYTE [todoTail + 16], NORTH

  mov al, momentumCounter
  inc al
  mov dil, 1
  test lastDirection, NORTH
  cmovz rax, rdi
  mov BYTE [todoTail + 17], al

  mov QWORD [todoTail + 24], 0

.notNorth:

  ; try going south
  test lastDirection, NORTH
  jnz .notSouth
  test lastDirection, SOUTH
  jz .notSouthMomentum
  cmp momentumCounter, 3
  jae .notSouth
.notSouthMomentum:

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax

  lea rax, [offset + SIZE]
  mov [todoTail + 0], rax
  
  movzx rax, BYTE [map + offset + SIZE]
  add rax, cost
  mov [todoTail + 8], rax
  
  mov BYTE [todoTail + 16], SOUTH

  mov al, momentumCounter
  inc al
  mov dil, 1
  test lastDirection, SOUTH
  cmovz rax, rdi
  mov BYTE [todoTail + 17], al

  mov QWORD [todoTail + 24], 0

.notSouth:

  ; try going east
  test lastDirection, WEST
  jnz .notEast
  test lastDirection, EAST
  jz .notEastMomentum
  cmp momentumCounter, 3
  jae .notEast
.notEastMomentum:

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax

  lea rax, [offset + 1]
  mov [todoTail + 0], rax
  
  movzx rax, BYTE [map + offset + 1]
  add rax, cost
  mov [todoTail + 8], rax
  
  mov BYTE [todoTail + 16], EAST

  mov al, momentumCounter
  inc al
  mov dil, 1
  test lastDirection, EAST
  cmovz rax, rdi
  mov BYTE [todoTail + 17], al

  mov QWORD [todoTail + 24], 0

.notEast:

  ; try going west
  test lastDirection, EAST
  jnz .notWest
  test lastDirection, WEST
  jz .notWestMomentum
  cmp momentumCounter, 3
  jae .notWest
.notWestMomentum:

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [todoTail + 24], rax
  mov todoTail, rax

  lea rax, [offset - 1]
  mov [todoTail + 0], rax
  
  movzx rax, BYTE [map + offset - 1]
  add rax, cost
  mov [todoTail + 8], rax
  
  mov BYTE [todoTail + 16], WEST

  mov al, momentumCounter
  inc al
  mov dil, 1
  test lastDirection, WEST
  cmovz rax, rdi
  mov BYTE [todoTail + 17], al

  mov QWORD [todoTail + 24], 0

.notWest:

.continueTraverseLoop:
  mov todoHead, [todoHead + 24]
  test todoHead, todoHead
  jnz .traverseLoop

  mov rax, targetOffset
  mov rdi, [costs + rax * 8]
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
map: resb SIZE * SIZE
costs: resq SIZE * SIZE
;; struct TodoEntry {
;;   qword offset;
;;   qword cost;
;;   byte lastDirection;
;;   byte momentumCounter;
;;   byte padding[6];
;;   qword next;
;; }
