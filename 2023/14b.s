extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define SIZE 128
%define x rbp
%define y r12
%define lastLine [rsp + 0]
%define map r13
%define mapPtr r14

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

  mov mapPtr, maps

  ; read file
  mov rdi, SIZE * SIZE
  call alloc
  mov [mapPtr], rax
  add mapPtr, 8

  mov map, [mapPtr - 8]

  mov y, 0
.readLoop:

  mov x, 0
.readLineLoop:
  mov rdi, map
  add rdi, x
  add rdi, y

  mov al, [curr]
  mov [rdi], al

  inc curr
  inc x

  cmp BYTE [curr], `\n`
  jne .readLineLoop

  inc curr
  add y, SIZE

  cmp curr, eof
  jb .readLoop

  mov lastLine, y

  ; do spin cycles
.findCycleLoop:
  mov rdi, SIZE * SIZE
  call alloc
  mov [mapPtr], rax
  add mapPtr, 8

  mov rdi, [mapPtr - 8]
  mov rsi, [mapPtr - 16]
  call spinCycle

  ; check - is this part of a cycle? If so, how long, and how long is the prefix?
  ; for each map from maps to mapPtr - 8
  mov curr, maps
.checkCycleLoop:
  mov rdi, [mapPtr - 8]
  mov rsi, [curr]
  mov rcx, SIZE * SIZE
  repe cmpsb
  jne .continueCheckCycleLoop

  ; found a cycle
  ; rdi = number of steps before cycle starts
  mov rdi, curr
  sub rdi, maps
  shr rdi, 3
  ; rsi = length of cycle
  lea rsi, [mapPtr - 8]
  sub rsi, curr
  shr rsi, 3

  jmp .endFindCycleLoop
.continueCheckCycleLoop:

  add curr, 8

  lea rax, [mapPtr - 8]
  cmp curr, rax
  jb .checkCycleLoop

  jmp .findCycleLoop
.endFindCycleLoop:

  ; output results
  ; find the cycle at (numCycles - leadIn) % length after cycle starting point
  mov rax, 1000000000
  sub rax, rdi
  cqo
  div rsi
  add rdi, rdx
  
  mov rdi, [maps + rdi * 8]
  mov rsi, lastLine
  call calculateLoad

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

%define map r8
%define changed sil
%define x rdx
%define y rcx
;; rdi = map to store rolled map in
;; rsi = map to read rolled map from
spinCycle:
  mov map, rdi

  ; copy over map
  mov rcx, SIZE * SIZE
  rep movsb

  ; roll rocks north
.rollNorthLoop:
  mov changed, 0

  ; roll rocks north once
  mov y, SIZE
.rollNorthOnceLoop:

  mov x, 0
.rollLineNorthOnceLoop:
  mov rax, map
  add rax, x
  add rax, y

  ; is current thing a rock?
  cmp BYTE [rax], 'O'
  jne .continueRollLineNorthOnceLoop

  ; current thing is a rock, is thing above an empty space?
  cmp BYTE [rax - SIZE], '.'
  jne .continueRollLineNorthOnceLoop

  ; roll rock up one, set changed
  mov BYTE [rax], '.'
  mov BYTE [rax - SIZE], 'O'
  mov changed, 1

.continueRollLineNorthOnceLoop:

  inc x

  mov rax, map
  add rax, x
  add rax, y

  cmp BYTE [rax], 0
  jne .rollLineNorthOnceLoop

  add y, SIZE

  cmp BYTE [map + y], 0
  jne .rollNorthOnceLoop

  test changed, changed
  jnz .rollNorthLoop

  ; roll rocks west
.rollWestLoop:
  mov changed, 0

  ; roll rocks west once
  mov y, 0
.rollWestOnceLoop:

  mov x, 1
.rollLineWestOnceLoop:
  mov rax, map
  add rax, x
  add rax, y

  ; is current thing a rock?
  cmp BYTE [rax], 'O'
  jne .continueRollLineWestOnceLoop

  ; current thing is a rock, is thing to the left an empty space?
  cmp BYTE [rax - 1], '.'
  jne .continueRollLineWestOnceLoop

  ; roll rock left one, set changed
  mov BYTE [rax], '.'
  mov BYTE [rax - 1], 'O'
  mov changed, 1

.continueRollLineWestOnceLoop:

  inc x

  mov rax, map
  add rax, x
  add rax, y

  cmp BYTE [rax], 0
  jne .rollLineWestOnceLoop

  add y, SIZE

  cmp BYTE [map + y], 0
  jne .rollWestOnceLoop

  test changed, changed
  jnz .rollWestLoop
  
  ; roll rocks south
.rollSouthLoop:
  mov changed, 0

  ; roll rocks south once
  mov y, 0
.rollSouthOnceLoop:

  mov x, 0
.rollLineSouthOnceLoop:
  mov rax, map
  add rax, x
  add rax, y

  ; is current thing a rock?
  cmp BYTE [rax], 'O'
  jne .continueRollLineSouthOnceLoop

  ; current thing is a rock, is thing below an empty space?
  cmp BYTE [rax + SIZE], '.'
  jne .continueRollLineSouthOnceLoop

  ; roll rock up one, set changed
  mov BYTE [rax], '.'
  mov BYTE [rax + SIZE], 'O'
  mov changed, 1

.continueRollLineSouthOnceLoop:

  inc x

  mov rax, map
  add rax, x
  add rax, y

  cmp BYTE [rax], 0
  jne .rollLineSouthOnceLoop

  add y, SIZE

  cmp BYTE [map + y + SIZE], 0
  jne .rollSouthOnceLoop

  test changed, changed
  jnz .rollSouthLoop

  ; roll rocks east
.rollEastLoop:
  mov changed, 0

  ; roll rocks east once
  mov y, 0
.rollEastOnceLoop:

  mov x, 0
.rollLineEastOnceLoop:
  mov rax, map
  add rax, x
  add rax, y

  ; is current thing a rock?
  cmp BYTE [rax], 'O'
  jne .continueRollLineEastOnceLoop

  ; current thing is a rock, is thing to the right an empty space?
  cmp BYTE [rax + 1], '.'
  jne .continueRollLineEastOnceLoop

  ; roll rock up one, set changed
  mov BYTE [rax], '.'
  mov BYTE [rax + 1], 'O'
  mov changed, 1

.continueRollLineEastOnceLoop:

  inc x

  mov rax, map
  add rax, x
  add rax, y

  cmp BYTE [rax + 1], 0
  jne .rollLineEastOnceLoop

  add y, SIZE

  cmp BYTE [map + y], 0
  jne .rollEastOnceLoop

  test changed, changed
  jnz .rollEastLoop

  ret

%undef map
%undef x
%undef y
%undef changed

%define map rdi
%define y rsi
%define x rdx
%define lineIndex rcx
%define accumulator rax

;; rdi = map
;; rsi = lastLine
calculateLoad:
  ; calculate load
  mov lineIndex, 0
  mov accumulator, 0
.calculateLoadLoop:
  sub y, SIZE
  inc lineIndex

  mov x, 0
.calculateLineLoadLoop:
  mov r8, map
  add r8, y
  add r8, x

  cmp BYTE [r8], 'O'
  jne .continueCalculateLineLoadLoop

  add accumulator, lineIndex

.continueCalculateLineLoadLoop:
  inc x

  mov r8, map
  add r8, y
  add r8, x

  cmp BYTE [r8], 0
  jne .calculateLineLoadLoop

  cmp y, 0
  jne .calculateLoadLoop

  ret

%undef map
%undef y
%undef x
%undef lineIndex
%undef accumulator

section .bss
maps: resq 4096
