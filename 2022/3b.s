extern mmap, exit, putlong, newline, findnl, searchc

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov r12, rax ; r12 = current character
  lea r13, [rax + rdx] ; r13 = end of file

  mov r14, 0 ; r14 = running total

  ; do while r12 < r13
.loop:

  mov rdi, r12
  call findnl
  mov rbx, rax ; rbx = newline 1

  lea rdi, [rbx + 1]
  call findnl
  mov rbp, rax ; rbp = newline 2

  lea rdi, [rbp + 1]
  call findnl
  mov r15, rax ; r15 = newline 3

  mov rdi, r12
  mov rsi, rbx
  mov rdx, rbp
  mov rcx, r15
  call findcommon
  movzx rax, al
  add r14, [priority + rax * 8]

  mov r12, r15
  inc r12

  cmp r12, r13
  jl .loop

  mov rdi, r14
  call putlong
  call newline

  mov dil, 0
  call exit

;; r12 = start of string
;; rbx = newline 1
;; rbp = newline 2
;; r15 = end of string
;; returns common character
;; contextual
findcommon:
  mov r8, r12 ; r8 = current character

.loop:
  mov dl, [r8]

  lea rdi, [rbx + 1]
  mov rsi, rbp
  call searchc
  cmp rax, rbp
  je .continue

  lea rdi, [rbp + 1]
  mov rsi, r15
  call searchc
  cmp rax, r15
  je .continue

  mov al, [rax]
  ret

.continue:

  inc r8

  jmp .loop

section .rodata
priority:
  resq 65 ; initial portion of ascii
  dq 27 ; A
  dq 28 ; B
  dq 29 ; C
  dq 30 ; D
  dq 31 ; E
  dq 32 ; F
  dq 33 ; G
  dq 34 ; H
  dq 35 ; I
  dq 36 ; J
  dq 37 ; K
  dq 38 ; L
  dq 39 ; M
  dq 40 ; N
  dq 41 ; O
  dq 42 ; P
  dq 43 ; Q
  dq 44 ; R
  dq 45 ; S
  dq 46 ; T
  dq 47 ; U
  dq 48 ; V
  dq 49 ; W
  dq 50 ; X
  dq 51 ; Y
  dq 52 ; Z
  resq 6 ; inter-alphabet gap
  dq 1 ; a
  dq 2 ; b
  dq 3 ; c
  dq 4 ; d
  dq 5 ; e
  dq 6 ; f
  dq 7 ; g
  dq 8 ; h
  dq 9 ; i
  dq 10 ; j
  dq 11 ; k
  dq 12 ; l
  dq 13 ; m
  dq 14 ; n
  dq 15 ; o
  dq 16 ; p
  dq 17 ; q
  dq 18 ; r
  dq 19 ; s
  dq 20 ; t
  dq 21 ; u
  dq 22 ; v
  dq 23 ; w
  dq 24 ; x
  dq 25 ; y
  dq 26 ; z