extern exit, mmap, putlong, newline, atol

section .text

%define endOfFile r12
%define currChar r13
%define currCell r14
%define accumulator r13
%define direction r13

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
  cmove rdi, currCell ; rdi = starting point

  inc currChar
  inc currCell

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  and currCell, ~255
  add currCell, 256 + 1

  cmp currChar, endOfFile
  jb .readLoop

  mov direction, -256
  mov currCell, rdi
.traverseLoop:

  ; mark current cell as visited
  mov BYTE [currCell], `X`

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

  ; count visited cells
  mov currCell, map
  mov accumulator, 0
.countLoop:

  mov rax, accumulator
  inc rax

  cmp BYTE [currCell], `X`
  cmove accumulator, rax

  inc currCell

  cmp currCell, map + 256 * 256
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

  ud2

section .bss
map: resb 256 * 256
