extern exit, mmap, findnotnum, atol

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define currLine r13

%define mapSize 70
; %define mapSize 6

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

  ; initialize map with border
  mov rdi, map
  mov rax, '#'
  mov rcx, 128 * 128
  rep stosb

  mov rsi, 128
.initLoop:

  mov rdi, 1
.initLineLoop:

  mov BYTE [map + rsi + rdi], '.'

  inc rdi
  cmp rdi, mapSize + 1
  jbe .initLineLoop

  add rsi, 128
  cmp rsi, (mapSize + 1) * 128
  jbe .initLoop

  ; read until path is blocked
.readLoop:
  mov currLine, currChar

  ; x
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  inc rax ; account for padding
  mov r15, rax

  inc currChar ; skip ','

  ; y
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  inc rax ; account for padding
  shl rax, 7 ; rax *= 2**7
  add r15, rax

  ; mark
  mov BYTE [map + 1 * r15], '#'

  inc currChar

  ; can we traverse? if so, output
  call canTraverse
  test al, al
  jz .endReadLoop

  jmp .readLoop
.endReadLoop:

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, currLine ; the last seen line
  mov rdx, currChar
  sub rdx, currLine ; between currLine and currChar
  syscall

  mov dil, 0
  call exit

;; uses global variable map
;; returns true if there is a path from 1, 1 to mapSize + 1, mapSize + 1, false otherwise
canTraverse:
%define todoHead rdi
%define curr rsi
%define steps rdx
  mov rax, -1
  mov rdi, visited
  mov rcx, 128 * 128
  rep stosq

  ;; template as while-loop-tail-recursive graph traversal with todo and combined visited/rsf accumulator
  mov todoHead, todo
  mov QWORD [todoHead + 0 * 8], 128 + 1
  mov QWORD [todoHead + 1 * 8], 0
  add todoHead, 2 * 8
.traverseLoop:

  sub todoHead, 2 * 8
  mov curr, [todoHead + 0 * 8]
  mov steps, [todoHead + 1 * 8]

  ; check - is this the exit
  cmp curr, (mapSize + 1) * 128 + (mapSize + 1)
  jne .notExit

  mov al, 1
  ret

.notExit:

  ; check - have we been here for equivalent or cheaper
  cmp steps, [visited + 8 * curr]
  jae .continueTraverseLoop

  ; record new, cheaper cost of getting here
  mov [visited + 8 * curr], steps

  ; consider moving around
  inc steps
  cmp BYTE [map + curr - 128], '#'
  je .notUp

  lea rax, [curr - 128]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notUp:
  cmp BYTE [map + curr + 128], '#'
  je .notDown

  lea rax, [curr + 128]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notDown:
  cmp BYTE [map + curr - 1], '#'
  je .notLeft

  lea rax, [curr - 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notLeft:
  cmp BYTE [map + curr + 1], '#'
  je .notRight

  lea rax, [curr + 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], steps
  add todoHead, 2 * 8

.notRight:

.continueTraverseLoop:

  cmp todoHead, todo
  ja .traverseLoop

  ; never got to the exit; bail
  mov al, 0
  ret

section .bss
map: resb 128 * 128
visited: resq 128 * 128
todo: resq 2 * 128 * 128
