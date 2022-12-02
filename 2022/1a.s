extern exit, mmap, putlong, findnl, atol, newline

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov r12, rax ; r12 = start of file
  lea r13, [rax + rdx] ; r13 = end of file

  mov rbx, 0 ; rbx = most calories
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
  cmp r14, rbx ; if current > most, most = current
  cmovg rbx, r14

  mov r14, 0 ; next elf

.continue:

  inc r12 ; move past this newline

  cmp r12, r13
  jl .loop

  cmp r14, rbx ; deal with last elf
  cmovg rbx, r14

  mov rdi, rbx
  call putlong
  call newline

  mov dil, 0
  call exit
