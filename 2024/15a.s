extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currLine r13
%define currCell r14
%define robot r15
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

  mov currLine, map
.readMapLoop:

  mov currCell, currLine
.readMapLineLoop:
  mov al, [currChar]
  mov [currCell], al
  
  cmp al, '@'
  cmove robot, currCell

  inc currChar
  inc currCell

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

  ; parse the direction of this arrow into rdx
  mov rax, -1
  cmp BYTE [currChar], '<'
  cmove rdx, rax
  je .parsedDirection
  
  mov rax, 1
  cmp BYTE [currChar], '>'
  cmove rdx, rax
  je .parsedDirection

  mov rax, -100
  cmp BYTE [currChar], '^'
  cmove rdx, rax
  je .parsedDirection

  mov rax, 100
  cmp BYTE [currChar], 'v'
  cmove rdx, rax

.parsedDirection:

  ; what's in that direction?
  cmp BYTE [robot + rdx], '#'
  je .continueSimulateLoop ; don't move into wall

  cmp BYTE [robot + rdx], '.'
  jne .notEmpty

  mov BYTE [robot], '.'
  add robot, rdx
  mov BYTE [robot], '@'

  jmp .continueSimulateLoop
.notEmpty:

  ; tried to move into a box; follow this direction until a non-box is found
  lea rdi, [robot + 2 * rdx]
.findStackEndLoop:
  cmp BYTE [rdi], '#'
  je .continueSimulateLoop ; can't push this stack into a wall

  cmp BYTE [rdi], '.'
  je .endFindStackEndLoop ; found open space to push into

  add rdi, rdx ; was another box, keep going
  jmp .findStackEndLoop
.endFindStackEndLoop:

  mov BYTE [rdi], 'O'
  mov BYTE [robot], '.'
  add robot, rdx
  mov BYTE [robot], '@'

.continueSimulateLoop:
  inc currChar

  cmp currChar, endOfFile
  jb .simulateLoop

  mov accumulator, 0
  mov currCell, 0
.sumLoop:

  cmp BYTE [map + currCell], 'O'
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

section .bss
map: resb 100 * 100
