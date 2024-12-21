extern exit, mmap, putlong, newline, atol

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define accumulator QWORD [rsp + 8]

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0, endOfFile
  ;; rsp + 8, accumulator

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov accumulator, 0

.loop:
  ; read in sequence (guaranteed four chars)
  mov eax, [currChar]
  mov [code], eax

  add currChar, 5 ; move to next sequence

  mov r13, code ; *r13 = next character to write
  mov r14, numeric.A ; r14 = current pointer location
  mov r15, robot1 ; r15 = end of buffer
  call constructSequence

  mov r13, robot1
  mov r14, directional.A
  mov r15, robot2
  call constructSequence

  mov r13, robot2
  mov r14, directional.A
  mov r15, me
  call constructSequence

  ; accumulator += atol(currChar - 5, currChar - 2) * (r15 - me)
  lea rdi, [currChar - 5]
  lea rsi, [currChar - 2]
  call atol

  sub r15, me
  mul r15
  add accumulator, rax

  cmp currChar, endOfFile
  jb .loop

.debug:
  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = current pointer location
;; rsi = pointer to desired character
searchMovement:
  mov rax, -3 ; rax = y-offset
.searchY:

  mov rdx, -2 ; rdx = x-offset
.searchX:

  lea rcx, [rdi + rax * 8]
  add rcx, rdx
  mov cl, [rcx]
  cmp cl, [rsi]
  jne .continueSearch

  ret

.continueSearch:

  inc rdx
  cmp rdx, 2
  jle .searchX

  inc rax
  cmp rax, 3
  jle .searchY

;; r13 = sequence string
;; r14 = pointer start pos
;; r15 = buffer end
constructSequence:
  ; construct sequence
  mov al, 0
  mov rcx, 128
  mov rdi, r15
  rep stosb

.loop:
  ; search for next character to write
  ; r8 = rax = vertical offset
  ; r9 = rdx = horizontal offset
  mov rdi, r14
  mov rsi, r13
  call searchMovement
  mov r8, rax
  mov r9, rdx

  ; taken from https://github.com/AllanTaylor314/AdventOfCode/blob/main/2024/21.py#L46

  ; are we going up and are we able to go up first?
  test r9, r9
  jng .notException
  cmp BYTE [r14 + r9], 0
  je .notException
  jmp .verticalFirst
.notException:

  ; can we do horizontal first?
  cmp BYTE [r14 + r9], 0
  jne .horizontalFirst

.verticalFirst:

  ; emit ^ or v
  mov al, '^'
  mov dl, 'v'
  mov rcx, r8
  neg rcx
  test r8, r8
  cmovns rax, rdx
  cmovns rcx, r8

  mov rdi, r15
  rep stosb
  mov r15, rdi

  ; emit < or >
  mov al, '<'
  mov dl, '>'
  mov rcx, r9
  neg rcx
  test r9, r9
  cmovns rax, rdx
  cmovns rcx, r9

  mov rdi, r15
  rep stosb
  mov r15, rdi

  jmp .continue
.horizontalFirst:

  ; emit < or >
  mov al, '<'
  mov dl, '>'
  mov rcx, r9
  neg rcx
  test r9, r9
  cmovns rax, rdx
  cmovns rcx, r9

  mov rdi, r15
  rep stosb
  mov r15, rdi

  ; emit ^ or v
  mov al, '^'
  mov dl, 'v'
  mov rcx, r8
  neg rcx
  test r8, r8
  cmovns rax, rdx
  cmovns rcx, r8

  mov rdi, r15
  rep stosb
  mov r15, rdi

.continue:
  
  ; emit A
  mov BYTE [r15], 'A'
  inc r15

  shl r8, 3
  add r14, r8
  add r14, r9 ; adjust pointer location

  inc r13 ; move to next character

  cmp BYTE [r13], 0
  jne .loop

section .bss
code: resb 8
robot1: resb 128
robot2: resb 128
me: resb 128

section .rodata
numeric:
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, '7', '8', '9', 0, 0, 0
db 0, 0, '4', '5', '6', 0, 0, 0
db 0, 0, '1', '2', '3', 0, 0, 0
db 0, 0, 0, '0'
.A: db 'A', 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
directional:
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, '^'
.A: db 'A', 0, 0, 0
db 0, 0, '<', 'v', '>', 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
db 0, 0, 0, 0, 0, 0, 0, 0
