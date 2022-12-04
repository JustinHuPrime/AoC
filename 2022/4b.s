extern mmap, exit, putlong, newline, findc, atol

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov r12, rax ; r12 = current character
  lea r13, [rax + rdx] ; r13 = end of file

  mov r14, 0 ; r14 = running total

  ; invariant
  ; r8 = start of range 1
  ; r9 = end of range 1
  ; r10 = start of range 2
  ; r11 = end of range 2

  ; do while r12 < r13
.loop:

  ; parse line
  ; first range start
  mov rdi, r12
  mov sil, '-'
  call findc
  mov rsi, rax
  call atol
  mov r8, rax

  ; first range end
  lea rdi, [rsi + 1]
  mov sil, ','
  call findc
  mov rsi, rax
  call atol
  mov r9, rax

  ; second range start
  lea rdi, [rsi + 1]
  mov sil, '-'
  call findc
  mov rsi, rax
  call atol
  mov r10, rax

  ; second range end
  lea rdi, [rsi + 1]
  mov sil, 0xa
  call findc
  mov rsi, rax
  call atol
  mov r11, rax

  ; next line
  lea r12, [rsi + 1]

  lea r15, [r14 + 1]
  
  ; if start1 <= end2 && start2 <= end1, increment
  cmp r8, r11
  jnle .continue
  cmp r10, r9
  cmovle r14, r15

.continue:

  cmp r12, r13
  jl .loop

  mov rdi, r14
  call putlong
  call newline

  mov dil, 0
  call exit