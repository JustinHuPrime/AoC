extern exit, mmap, putlong, newline, atol

section .text

%define endOfFile r12
%define currChar r13
%define currCell r14
%define accumulator r12
%define direction r13
%define obstructionPos r15
%define startPos rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  mov currCell, map + 1 + 256
.readLoop:

.readLineLoop:

  mov al, [currChar]
  mov [currCell], al
  cmp al, `^`
  cmove startPos, currCell

  inc currChar
  inc currCell

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  and currCell, ~255
  add currCell, 256 + 1

  cmp currChar, endOfFile
  jb .readLoop

  ; for each possible position to place a new obstruction
  mov obstructionPos, map
  mov accumulator, 0
.countLoop:

  ; if it's outside the map or already obstructed, continue
  cmp BYTE [obstructionPos], `.`
  jne .continueCountLoop

  ; place the obstruction
  mov BYTE [obstructionPos], `#`

  ; traverse until loop detected or 
  mov rdi, visited
  mov rcx, 256 * 256 * 4
  mov al, 0
  rep stosb
  mov direction, -256
  mov currCell, startPos
.traverseLoop:

  ; check - have we been here before?
  mov rdi, direction
  call directionToOffset
  mov rdi, currCell
  sub rdi, map

  cmp BYTE [visited + rdi * 4 + rax], 0
  jne .looped

  mov BYTE [visited + rdi * 4 + rax], 1

  ; while we can't move in current direction, turn right
.turnLoop:
  cmp BYTE [currCell + direction], `#`
  jne .endTurnLoop

  mov rdi, direction
  call turnRight
  mov direction, rax

  jmp .turnLoop
.endTurnLoop:

  ; move
  add currCell, direction

  cmp BYTE [currCell], 0
  jne .traverseLoop
.looped:

  ; remove the obstruction
  mov BYTE [obstructionPos], `.`

  ; did we leave traversal because of OOB?
  cmp BYTE [currCell], 0
  je .continueCountLoop

  inc accumulator

.continueCountLoop:
  inc obstructionPos

  cmp obstructionPos, map + 256 * 256
  jb .countLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = current direction (as array offset)
;; returns direction after turning right
turnRight:
  cmp rdi, -256
  jne .notUp

  mov rax, 1
  ret

.notUp:
  cmp rdi, 1
  jne .notRight

  mov rax, 256
  ret

.notRight:
  cmp rdi, 256
  jne .notDown

  mov rax, -1
  ret

.notDown:
  cmp rdi, -1
  jne .notLeft

  mov rax, -256
  ret

.notLeft:

  ud1 rdi, rdi

;; rdi = current direction (as array offset)
;; returns index of direction where:
;; up = 0
;; right = 1
;; down = 2
;; left = 3
;; none = -1
directionToOffset:
  cmp rdi, -256
  jne .notUp

  mov rax, 0
  ret

.notUp:
  cmp rdi, 1
  jne .notRight

  mov rax, 1
  ret

.notRight:
  cmp rdi, 256
  jne .notDown

  mov rax, 2
  ret

.notDown:
  cmp rdi, -1
  jne .notLeft

  mov rax, 3
  ret

.notLeft:

  ud1 rdi, rdi

section .bss
map: resb 256 * 256
visited: resb 256 * 256 * 4
