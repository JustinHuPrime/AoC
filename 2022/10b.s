extern mmap, exit, atol, findnl

section .text

global _start:function
_start:
  ; fill screen with spaces
  mov rcx, 40 * 6
  mov al, ' '
  mov rdi, screen
  rep stosb

  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  mov r13, 1 ; r13 = x register
  mov r12, 1 ; r12 = clock
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

  mov rcx, 6
.displayLoop:

  push rcx

  ; mov this line's 40 bytes onto the screen
  mov rsi, 6
  sub rsi, rcx
  mov rdi, 40
  imul rsi, rdi
  add rsi, screen
  mov rcx, 40
  lea rdi, [rsp - 41]
  rep movsb

  mov BYTE [rdi], 0xa ; add newline

  mov rax, 1 ; write
  lea rsi, [rsp - 41] ; using redzone buffer
  mov rdi, 1 ; to stdout
  mov rdx, 41 ; 41 bytes
  syscall

  pop rcx

  loop .displayLoop

  mov dil, 0
  call exit

;; advances the clock by one tick
;; r13 = x register
;; r12 = clock
;; mutates accumulator
;; clobbers
tick:
  ; if (r12 - 1) % 40 is within 1 of r13, mark screen[r12 - 1]
  lea rax, [r12 - 1]
  mov rdx, 0
  mov rdi, 40
  div rdi ; rdx = (r12 - 1) % 40

  ; get absolute value of (r12 - 1) % 40 - r13
  sub rdx, r13
  jns .positive
  
  neg rdx ; rdx < 0; rdx =-

.positive:

  cmp rdx, 1
  jg .noMark

  mov BYTE [screen + r12 - 1], '#'

.noMark:
  inc r12

  ret

section .bss
screen:
  resb 40 * 6