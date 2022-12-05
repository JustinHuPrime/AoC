extern mmap, exit, findnl, findspace, newline, alloc, putc, atol, putlong

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 6 * 8
  ; stack slots:
  ; rsp + 0 = start of file
  ; rsp + 8 = end of file
  ; rsp + 16 = width of stacks
  ; rsp + 24 = height of stacks
  ; rsp + 32 = end of stacks
  ; rsp + 40 = number of boxes

  ; save start and end of file
  mov [rsp + 0], rax
  lea rax, [rax + rdx]
  mov [rsp + 8], rax

  ; get width of stacks
  mov rdi, [rsp + 0]
  call findnl
  sub rax, [rsp + 0]
  inc rax
  sar rax, 2 ; stride of 4
  mov [rsp + 16], rax

  ; get height of stacks
  mov rbx, 0 ; rbp = height of stacks
  mov r12, [rsp + 0] ; r12 = current line

  ; while current line's second character isn't 1
.heightLoop:
  cmp BYTE [r12 + 1], '1'
  je .endHeightLoop

  inc rbx

  mov rdi, r12
  call findnl
  lea r12, [rax + 1]

  jmp .heightLoop
.endHeightLoop:

  mov [rsp + 24], rbx
  mov [rsp + 32], r12 ; also save end of stacks

  ; count number of boxes

  ; for (r12 = start of file + 1; r12 < end of stacks; r12 += 4)
  mov rbx, 0 ; rbx = number of boxes
  mov r12, [rsp + 0]
  inc r12
.countLoop:
  cmp r12, [rsp + 32]
  jnl .endCountLoop

  lea r13, [rbx + 1] ; if current box has a value, increment counter
  cmp BYTE [r12], ' '
  cmovne rbx, r13

  add r12, 4

  jmp .countLoop
.endCountLoop:

  mov [rsp + 40], rbx

  ; allocate [width] stacks, each with room for [number of boxes] bytes

  mov rdi, [rsp + 16]
  shl rdi, 3
  call alloc
  mov rbx, rax ; rbx = pointer to array of stacks

  ; for each of the stacks initialize it for [number of boxes] bytes

  ; for (r12 = 0; r12 < [width]; ++r12)
  mov r12, 0
  ; mov rbx, rbx ; rbx = pointer to array of stacks
.initStackLoop:
  cmp r12, [rsp + 16]
  jnl .endInitStackLoop

  mov rdi, [rsp + 40]
  call alloc
  mov [rbx + r12 * 8], rax

  inc r12

  jmp .initStackLoop
.endInitStackLoop:

  ; read stacks

  mov r12, [rsp + 32] ; r12 = current line
  ; mov rbx, rbx ; rbx = pointer to array of stacks

  ; do-while r12 > [start]
.readStackLoop:

  ; move to next line
  mov r13, [rsp + 16]
  shl r13, 2
  sub r12, r13

  ; for (r13 = 0; r13 < width; ++r13)
  mov r13, 0
.readLineLoop:
  cmp r13, [rsp + 16]
  jnl .endReadLineLoop

  mov r15b, BYTE [r12 + r13 * 4 + 1] ; r15 = maybe data to write
  cmp r15b, ' '
  je .continueReadLineLoop

  mov r14, [rbx + r13 * 8] ; r14 = address to write to
  mov BYTE [r14], r15b
  inc QWORD [rbx + r13 * 8] ; increment stack pointer

.continueReadLineLoop:

  inc r13

  jmp .readLineLoop
.endReadLineLoop:

  ; r15 = temporary holding stack
  mov rdi, [rsp + 40]
  call alloc
  mov r15, rax

  cmp r12, [rsp + 0]
  jg .readStackLoop

  ; start parsing instructions
  ; mov rbx, rbx ; rbx = pointer to array of stacks
  mov rdi, [rsp + 32]
  call findnl
  add rax, 2
  mov rbp, rax ; rbp = pointer to start of instructions/current character

  ; while rbp < [end of file]
.instructionLoop:
  cmp rbp, [rsp + 8]
  jnl .endInstructionLoop

  add rbp, 5 ; skip "move "

  ; parse number
  mov rdi, rbp
  call findspace
  mov rsi, rax
  call atol
  mov r12, rax ; r12 = how many to move

  lea rbp, [rsi + 6] ; skip " from "

  ; parse number
  mov rdi, rbp
  call findspace
  mov rsi, rax
  call atol
  mov r13, rax ; r13 = from where

  lea rbp, [rsi + 4] ; skip " to "

  ; parse number
  mov rdi, rbp
  call findnl
  mov rsi, rax
  call atol
  mov r14, rax ; r14 = to where

  lea rbp, [rsi + 1] ; skip newline

  ; process move
  ; for (rax = r12; rax > 0; --rax)
  mov rax, r12
.moveLoop1:
  test rax, rax
  jz .endMoveLoop1

  ; pop a thing from r13
  mov rdi, [rbx + (r13 * 8) - 8] ; rdi = pointer to read from
  mov sil, BYTE [rdi - 1] ; sil = popped data
  dec QWORD [rbx + (r13 * 8) - 8]

  ; push a thing to r15
  mov BYTE [r15], sil
  inc r15

  dec rax

  jmp .moveLoop1
.endMoveLoop1:

  ; for (rax = r12; rax > 0; --rax
  mov rax, r12
.moveLoop2:
  test rax, rax
  jz .endMoveLoop2

  ; popa  thing from r15
  mov sil, BYTE [r15 - 1]
  dec r15

  ; push a thing to r14
  mov rdi, [rbx + (r14 * 8) - 8]
  mov BYTE [rdi], sil
  inc QWORD [rbx + (r14 * 8) - 8]

  dec rax
  
  jmp .moveLoop2
.endMoveLoop2:

  jmp .instructionLoop
.endInstructionLoop:

  ; for (r12 = 0; r12 < [width]; ++r12)
  mov r12, 0
.outputLoop:
  cmp r12, [rsp + 16]
  jnl .endOutputLoop

  mov rdi, [rbx + r12 * 8]
  mov dil, [rdi - 1]
  call putc

  inc r12

  jmp .outputLoop
.endOutputLoop:

  call newline

  mov dil, 0
  call exit