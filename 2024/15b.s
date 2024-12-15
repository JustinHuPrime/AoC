extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currLine r13
%define currCell r14
%define robot r15
%define accumulator r12
%define direction r13

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

  mov currLine, map
.readMapLoop:

  mov currCell, currLine
.readMapLineLoop:
  mov al, [currChar]

  cmp al, '#'
  jne .notWall

  mov WORD [currCell], '##'

  jmp .continueReadMapLineLoop
.notWall:

  cmp al, '.'
  jne .notEmpty

  mov WORD [currCell], '..'

  jmp .continueReadMapLineLoop
.notEmpty:

  cmp al, 'O'
  jne .notBox

  mov WORD [currCell], '[]'

  jmp .continueReadMapLineLoop
.notBox:

  ; cmp al, '@' ; must be robot
  mov WORD [currCell], '@.'
  mov robot, currCell
  
.continueReadMapLineLoop:

  inc currChar
  add currCell, 2

  cmp BYTE [currChar], `\n`
  jne .readMapLineLoop

  inc currChar ; skip newline
  add currLine, 100

  cmp BYTE [currChar], `\n`
  jne .readMapLoop

  inc currChar ; skip terminal newline

.simulateLoop:
  cmp BYTE [currChar], `\n`
  je .continueSimulateLoop

  ; parse the direction of this arrow into direction
  mov rax, -1
  cmp BYTE [currChar], '<'
  cmove direction, rax
  je .parsedDirection
  
  mov rax, 1
  cmp BYTE [currChar], '>'
  cmove direction, rax
  je .parsedDirection

  mov rax, -100
  cmp BYTE [currChar], '^'
  cmove direction, rax
  je .parsedDirection

  mov rax, 100
  cmp BYTE [currChar], 'v'
  cmove direction, rax

.parsedDirection:

  ; what's in that direction?
  cmp BYTE [robot + direction], '#'
  je .continueSimulateLoop ; don't move into wall

  cmp BYTE [robot + direction], '.'
  jne .isBox

  mov BYTE [robot], '.'
  add robot, direction
  mov BYTE [robot], '@'

  jmp .continueSimulateLoop
.isBox:

  ; tried to move into a box; which way were we moving again?
  cmp BYTE [currChar], '<'
  jne .notLeft

  mov rdi, robot
  add rdi, direction
  add rdi, direction
  add rdi, direction
  mov rcx, 2
.findStackLeftLoop:
  cmp BYTE [rdi], '#'
  je .continueSimulateLoop ; can't push this stack into a wall

  cmp BYTE [rdi], '.'
  je .endFindStackLeftLoop ; found open space to push into

  add rdi, direction ; was another box, keep going
  inc rcx
  jmp .findStackLeftLoop
.endFindStackLeftLoop:

  ; mov rdi, rdi
  mov rsi, rdi
  sub rsi, direction
  ; mov rcx, rcx
  rep movsb ; move stack left

  mov BYTE [robot], '.'
  add robot, direction
  mov BYTE [robot], '@'

  jmp .continueSimulateLoop
.notLeft:

  cmp BYTE [currChar], '>'
  jne .notRight

  mov rdi, robot
  add rdi, direction
  add rdi, direction
  add rdi, direction
  mov rcx, 2
.findStackRightLoop:
  cmp BYTE [rdi], '#'
  je .continueSimulateLoop ; can't push this stack into a wall

  cmp BYTE [rdi], '.'
  je .endFindStackRightLoop ; found open space to push into

  add rdi, direction ; was another box, keep going
  inc rcx
  jmp .findStackRightLoop
.endFindStackRightLoop:

  std
  ; mov rdi, rdi
  mov rsi, rdi
  sub rsi, direction
  ; mov rcx, rcx
  rep movsb ; move stack left
  cld

  mov BYTE [robot], '.'
  add robot, direction
  mov BYTE [robot], '@'

  jmp .continueSimulateLoop
.notRight:

  ; moving up and down; recursive solution needed
  lea rdi, [robot + direction]
  lea rsi, [robot + direction - 1]
  cmp BYTE [robot + direction], ']'
  cmove rdi, rsi ; rdi = left part of box
  push rdi
  mov rsi, direction
  call canmove
  pop rdi

  test al, al
  jz .continueSimulateLoop ; can't move, bail
  
  ; mov rdi, rdi
  mov rsi, direction
  call domove

  mov BYTE [robot], '.'
  add robot, direction
  mov BYTE [robot], '@'

.continueSimulateLoop:
  inc currChar

  cmp currChar, endOfFile
  jb .simulateLoop

  mov accumulator, 0
  mov currCell, 0
.sumLoop:

  cmp BYTE [map + currCell], '['
  jne .continueSumLoop

  add accumulator, currCell

.continueSumLoop:

  inc currCell

  cmp currCell, 100 * 100
  jb .sumLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = box to check
;; rsi = direction
;; clobbers rdi
canmove:
  ; base case 1 - either is a wall
  cmp BYTE [rdi + rsi], '#'
  je .cantmove
  cmp BYTE [rdi + rsi + 1], '#'
  je .cantmove
  ; base case 2 - both are empty
  cmp BYTE [rdi + rsi], '.'
  jne .notEmpty
  cmp BYTE [rdi + rsi + 1], '.'
  jne .notEmpty
  mov al, 1
  ret

.notEmpty:

  ; at least one is a box part
  cmp BYTE [rdi + rsi], '['
  jne .notAlignedBox

  lea rdi, [rdi + rsi]
  jmp canmove ; tail call - only one box to check

.notAlignedBox:
  cmp BYTE [rdi + rsi], ']'
  jne .noLeftBox

  push rdi
  lea rdi, [rdi + rsi - 1]
  call canmove
  pop rdi
  test al, al
  jz .cantmove

.noLeftBox:
  cmp BYTE [rdi + rsi + 1], '.'
  je .success

  lea rdi, [rdi + rsi + 1]
  jmp canmove

.cantmove:
  mov al, 0
  ret

.success:
  mov al, 1
  ret

;; rdi = box to move
;; rsi = direction
;; clobbers rdi
domove:
  ; maybe move aligned box
  cmp BYTE [rdi + rsi], '['
  jne .noAligned

  push rdi
  lea rdi, [rdi + rsi]
  call domove
  pop rdi

  jmp .moveThis
.noAligned:

  ; maybe move left box
  cmp BYTE [rdi + rsi - 1], '['
  jne .noLeft

  push rdi
  lea rdi, [rdi + rsi - 1]
  call domove
  pop rdi

.noLeft:
  ; maybe move right box
  cmp BYTE [rdi + rsi + 1], '['
  jne .moveThis

  push rdi
  lea rdi, [rdi + rsi + 1]
  call domove
  pop rdi

.moveThis:
  mov WORD [rdi], '..'
  mov WORD [rdi + rsi], '[]'
  ret

section .bss
map: resb 100 * 100
