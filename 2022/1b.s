extern exit, mmap, putlong, findnl, atol, newline

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov r12, rax ; r12 = start of file
  lea r13, [rax + rdx] ; r13 = end of file

  mov rbx, 0 ; rbx = most calories
  mov rbp, 0 ; rbp = second-most calories
  mov r15, 0 ; r15 = third-most calories
  mov r14, 0 ; r14 = current calories

  ; r12 = current character
  ; do while r12 < r13
.loop:

  mov rdi, r12
  call findnl

  cmp rax, r12
  je .equal

  ; add this number to current elf
  mov rdi, r12
  mov rsi, rax
  call atol
  add r14, rax

  mov r12, rsi ; rsi remains unclobbered as end of string

  jmp .continue
.equal:

  ; this elf is done - compare
  cmp r14, rbx ; if current > most, most = current, current = old most
  jle .second

  mov rax, rbx
  mov rbx, r14
  mov r14, rax

.second:
  cmp r14, rbp ; if current > second-most, second-most = current
  jle .third

  mov rax, rbp
  mov rbp, r14
  mov r14, rax

.third:
  cmp r14, r15 ; else if current > third-most, third-most = current
  jle .next

  mov rax, r15
  mov r15, r14
  mov r14, rax

.next:
  mov r14, 0 ; next elf

.continue:

  inc r12 ; move past this newline

  cmp r12, r13
  jl .loop

  ; deal with last elf
  cmp r14, rbx ; if current > most, most = current, current = old most
  jle .lastsecond

  mov rax, rbx
  mov rbx, r14
  mov r14, rax

.lastsecond:
  cmp r14, rbp ; if current > second-most, second-most = current
  jle .lastthird

  mov rax, rbp
  mov rbp, r14
  mov r14, rax

.lastthird:
  cmp r14, r15 ; else if current > third-most, third-most = current
  jle .lastnext

  mov rax, r15
  mov r15, r14
  mov r14, rax

.lastnext:

  mov rdi, rbx
  add rdi, rbp
  add rdi, r15
  call putlong
  call newline

  mov dil, 0
  call exit
