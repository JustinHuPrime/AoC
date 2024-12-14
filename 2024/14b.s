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

  mov r15, 0
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

  inc r15

  ; do output
  mov rdi, r15
  call putlong
  call newline

  mov rdi, renderBuffer
  mov al, ' '
  mov rcx, (width + 1) * height
  rep stosb

  mov rdi, renderBuffer + width
.newlineLoop:
  mov BYTE [rdi], `\n`
  add rdi, width + 1
  cmp rdi, renderBuffer + (width + 1) * height
  jb .newlineLoop

  mov currRobot, robots
.renderElementLoop:

  mov rax, [currRobot + 1 * 8]
  mov rdi, width + 1
  mul rdi
  add rax, [currRobot + 0 * 8]
  mov BYTE [renderBuffer + rax], '*'

  add currRobot, 4 * 8

  cmp QWORD [currRobot + 2 * 8], 0
  jne .renderElementLoop

  mov rax, 1 ; write
  mov rsi, renderBuffer ; from buffer
  mov rdi, 1 ; to stdout
  mov rdx, (width + 1) * height
  syscall

  cmp r15, 16384
  jbe .simulateLoop

  mov dil, 0
  call exit

section .bss

robots: resq 512 * 4
;; struct Robot {
;;   signed qword px, py;
;;   signed qword vx, vy;
;; }
renderBuffer: resb (width + 1) * height
