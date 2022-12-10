extern mmap, exit, newline, atol, findnl, putslong

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  mov r13, 1 ; r13 = x register
  mov r12, 1 ; r12 = clock
  mov rbp, 0 ; rbp = accumulator
  ; while (r15 < r14)
.loop:
  cmp r15, r14
  jnl .endLoop

  ; decode instruction
  cmp BYTE [r15], 'a'
  jne .noop

  add r15, 5 ; skip "addx "
  cmp BYTE [r15], '-' ; is this signed?
  je .subx
  ; addx literal

  call tick
  call tick

  mov rdi, r15
  call findnl
  mov rdi, r15
  mov rsi, rax
  lea r15, [rax + 1] ; skip number + newline
  call atol ; rax = literal, signed
  add r13, rax

  jmp .endInst
.subx:
  ; addx -literal
  inc r15 ; skip "-"

  call tick
  call tick

  mov rdi, r15
  call findnl
  mov rdi, r15
  mov rsi, rax
  lea r15, [rax + 1] ; skip number + newline
  call atol
  neg rax ; rax = literal, signed
  add r13, rax

  jmp .endInst
.noop:
  ; noop
  
  call tick

  add r15, 5 ; skip "noop", newline

.endInst:

  jmp .loop
.endLoop:

  mov rdi, rbp
  call putslong
  call newline

  mov dil, 0
  call exit

;; advances the clock by one tick
;; r13 = x register
;; r12 = clock
;; rbp = accumulator
;; mutates accumulator
;; clobbers
tick:
  ; if (r12 - 20) % 40 == 0
  cmp r12, 20
  jl .noSignal
  mov rdx, 0
  mov rax, r12
  sub rax, 20
  mov rsi, 40
  div rsi
  test rdx, rdx
  jnz .noSignal

  mov rax, r13
  imul rax, r12
  add rbp, rax

.noSignal:

  inc r12

  ret