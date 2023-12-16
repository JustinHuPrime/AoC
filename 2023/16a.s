extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define x rbp
%define y r12
%define SIZE 128
%define todoHead r13
%define TODO_ENTRY_SIZE (4 * 8)
%define UP    0b1000
%define RIGHT 0b0100
%define DOWN  0b0010
%define LEFT  0b0001
%define direction rbx
%define directionb bl
%define accumulator rdi

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof/lastLine

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; read in map, with padding
  mov y, SIZE
.readMapLoop:

  mov x, 1

.readMapLineLoop:
  mov al, [curr]
  mov [map + x + y], al

  inc curr
  inc x

  cmp BYTE [curr], `\n`
  jne .readMapLineLoop

  add y, SIZE
  inc curr ; skip newline

  cmp curr, eof
  jb .readMapLoop

  ; simulate beams

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov todoHead, rax

  mov QWORD [todoHead + 0], 1
  mov QWORD [todoHead + 8], SIZE
  mov QWORD [todoHead + 16], RIGHT
  mov QWORD [todoHead + 24], 0

  ; do-while todoHead != NULL
.traverseLoop:
  ; pop entry
  mov x, [todoHead + 0]
  mov y, [todoHead + 8]
  mov direction, [todoHead + 16]
  mov todoHead, [todoHead + 24]

  ; check - has the beam wandered off the edge of the map?
  ; skip if so
  mov al, [map + x + y]
  test al, al
  jz .continueTraverseLoop

  ; check - has the current cell been energized from this direction already
  ; skip if so
  test directionb, [energized + x + y]
  jnz .continueTraverseLoop

  ; mark current cell energized from this direction
  or BYTE [energized + x + y], directionb

  ; consider current cell
  cmp al, '/'
  jne .notForwardMirror

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  test direction, UP
  jz .forwardNotUp

  lea rax, [x + 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], RIGHT

  jmp .continueTraverseLoop
.forwardNotUp:

  test direction, RIGHT
  jz .forwardNotRight

  mov [todoHead + 0], x
  lea rax, [y - SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], UP

  jmp .continueTraverseLoop
.forwardNotRight:

  test direction, DOWN
  jz .forwardNotDown

  lea rax, [x - 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], LEFT

  jmp .continueTraverseLoop
.forwardNotDown:

  ; test direction, LEFT
  ; jz .forwardNotLeft

  mov [todoHead + 0], x
  lea rax, [y + SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], DOWN

  ; jmp .continueTraverseLoop
; .forwardNotLeft:

  jmp .continueTraverseLoop
.notForwardMirror:

  cmp al, '\'
  jne .notBackwardMirror

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  test direction, UP
  jz .backwardNotUp

  lea rax, [x - 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], LEFT

  jmp .continueTraverseLoop
.backwardNotUp:

  test direction, RIGHT
  jz .backwardNotRight

  mov [todoHead + 0], x
  lea rax, [y + SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], DOWN

  jmp .continueTraverseLoop
.backwardNotRight:

  test direction, DOWN
  jz .backwardNotDown

  lea rax, [x + 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], RIGHT

  jmp .continueTraverseLoop
.backwardNotDown:

  ; test direction, LEFT
  ; jz .backwardNotLeft

  mov [todoHead + 0], x
  lea rax, [y - SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], UP

  ; jmp .continueTraverseLoop
; .backwardNotLeft:

  jmp .continueTraverseLoop
.notBackwardMirror:

  cmp al, '|'
  jne .notVerticalSplitter

  test direction, RIGHT | LEFT
  jz .notHorizontalSplitter ; treat it as a dot if we don't split

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  mov [todoHead + 0], x
  lea rax, [y - SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], UP

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  mov [todoHead + 0], x
  lea rax, [y + SIZE]
  mov [todoHead + 8], rax
  mov QWORD [todoHead + 16], DOWN
  
  jmp .continueTraverseLoop
.notVerticalSplitter:

  cmp al, '-'
  jne .notHorizontalSplitter

  test direction, UP | DOWN
  jz .notHorizontalSplitter ; treat it as a dot if we don't split

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  lea rax, [x + 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], RIGHT

  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  lea rax, [x - 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y
  mov QWORD [todoHead + 16], LEFT

  jmp .continueTraverseLoop
.notHorizontalSplitter:
  ; cmp al, '.'
  ; jne .notDot

  ; has to be a dot
  mov rdi, TODO_ENTRY_SIZE
  call alloc
  mov [rax + 24], todoHead
  mov todoHead, rax

  mov [todoHead + 16], direction

  test direction, UP
  jz .dotNotUp

  mov [todoHead + 0], x
  lea rax, [y - SIZE]
  mov [todoHead + 8], rax

  jmp .continueTraverseLoop
.dotNotUp:

  test direction, RIGHT
  jz .dotNotRight

  lea rax, [x + 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y

  jmp .continueTraverseLoop
.dotNotRight:

  test direction, DOWN
  jz .dotNotDown

  mov [todoHead + 0], x
  lea rax, [y + SIZE]
  mov [todoHead + 8], rax

  jmp .continueTraverseLoop
.dotNotDown:

  ; test direction, LEFT
  ; jz .dotNotLeft

  lea rax, [x - 1]
  mov [todoHead + 0], rax
  mov [todoHead + 8], y

  ; jmp .continueTraverseLoop
; .dotNotLeft:

  ; jmp .continueTraverseLoop
; .notDot:

.continueTraverseLoop:

  test todoHead, todoHead
  jnz .traverseLoop

  ; count energized cells
  mov y, SIZE
  mov accumulator, 0
.countCellsLoop:

  mov x, 1
.countCellsRowLoop:

  lea rsi, [rdi + 1]
  mov al, BYTE [energized + x + y]
  test al, al
  cmovnz rdi, rsi

  inc x

  cmp BYTE [map + x + y], 0
  jne .countCellsRowLoop

  add y, SIZE
  
  cmp BYTE [map + 1 + y], 0
  jne .countCellsLoop

  ; mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
map: resb SIZE * SIZE
energized: resb SIZE * SIZE
;; struct TodoEntry {
;;   qword x;
;;   qword y;
;;   qword direction; // direction beam is travelling 0bURDL
;;   qword nextEntry;
;; }
