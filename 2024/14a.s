extern exit, mmap, putlong, newline, findnotsnum, atosl

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currRobot r13
%define width 101
%define height 103
%define halfHeight 51
%define halfWidth 50
; %define height 7
; %define halfHeight 3
; %define width 11
; %define halfWidth 5

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

  mov currRobot, robots
.readLoop:

  add currChar, 2 ; skip "p="

  mov rdi, currChar
  call findnotsnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atosl
  mov [currRobot + 0 * 8], rax

  add currChar, 1 ; skip ","

  mov rdi, currChar
  call findnotsnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atosl
  mov [currRobot + 1 * 8], rax

  add currChar, 3 ; skip " v="

  mov rdi, currChar
  call findnotsnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atosl
  mov [currRobot + 2 * 8], rax

  add currChar, 1 ; skip ","

  mov rdi, currChar
  call findnotsnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atosl
  mov [currRobot + 3 * 8], rax

  add currChar, 1 ; skip newline

  add currRobot, 4 * 8

  cmp currChar, endOfFile
  jb .readLoop

  mov rcx, 100
.simulateLoop:

  mov currRobot, robots
.simulateElementLoop:

  ; robot.px = (robot.px + robot.vx + width) % width
  mov rax, [currRobot + 0 * 8]
  add rax, [currRobot + 2 * 8]
  add rax, width
  cqo
  mov rdi, width
  idiv rdi
  mov [currRobot + 0 * 8], rdx

  ; robot.py = (robot.py + robot.vy + height) % height
  mov rax, [currRobot + 1 * 8]
  add rax, [currRobot + 3 * 8]
  add rax, height
  cqo
  mov rdi, height
  idiv rdi
  mov [currRobot + 1 * 8], rdx

  add currRobot, 4 * 8

  cmp QWORD [currRobot + 2 * 8], 0
  jne .simulateElementLoop

  dec rcx
  test rcx, rcx
  jnz .simulateLoop

  mov r8, 0 ; r8 = quadrant 1 robots
  mov r9, 0 ; r9 = quadrant 2 robots
  mov r10, 0 ; r10 = quadrant 3 robots
  mov r11, 0 ; r11 = quadrant 4 robots
  mov currRobot, robots
.countLoop:

  ; < 51 = left, > 51 = right
  cmp QWORD [currRobot + 0 * 8], halfWidth
  jl .leftHalf
  jg .rightHalf
  jmp .continueCountLoop

.leftHalf:
  cmp QWORD [currRobot + 1 * 8], halfHeight
  jl .lowerLeft
  jg .upperLeft
  jmp .continueCountLoop

.lowerLeft:

  inc r10

  jmp .continueCountLoop

.upperLeft:

  inc r9

  jmp .continueCountLoop

.rightHalf:
  cmp QWORD [currRobot + 1 * 8], halfHeight
  jl .lowerRight
  jg .upperRight
  jmp .continueCountLoop

.lowerRight:

  inc r11

  jmp .continueCountLoop

.upperRight:

  inc r8

  jmp .continueCountLoop

.continueCountLoop:

  add currRobot, 4 * 8

  cmp QWORD [currRobot + 2 * 8], 0
  jne .countLoop

  mov rax, r8
  mul r9
  mul r10
  mul r11

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

robots: resq 512 * 4
;; struct Robot {
;;   signed qword px, py;
;;   signed qword vx, vy;
;; }
