extern mmap, exit, putlong, newline, atol, findnl, alloc

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  ; find out length of input, in steps
  mov r13, 0 ; r13 = length of input
  mov r12, r15 ; r12 = current character in input
.getLengthLoop:
  cmp r12, r14
  jnl .endGetLengthLoop

  ; skip direction
  add r12, 2

  ; parse number
  mov rdi, r12
  call findnl
  mov rdi, r12
  mov rsi, rax
  lea r12, [rax + 1]
  call atol
  add r13, rax

  jmp .getLengthLoop
.endGetLengthLoop:

  ; allocate space for input
  mov rdi, r13
  call alloc
  mov r12, rax ; r12 = input, as single moves
  add r13, r12 ; r13 = end of single-move input

  ; read input
  mov r11, r15 ; r11 = current character
  mov r10, r12 ; r10 = current input space
.readLoop:
  cmp r11, r14
  jnl .endReadLoop

  ; get direction
  mov bl, [r11] ; bl = direction character
  add r11, 2

  ; parse number
  mov rdi, r11
  call findnl
  mov rdi, r11
  mov rsi, rax
  lea r11, [rax + 1]
  call atol

  ; store into input array
  mov rcx, rax
  mov al, bl
  mov rdi, r10
  rep stosb
  mov r10, rdi

  jmp .readLoop
.endReadLoop:

  ; do a bounds check
  mov r15, 0 ; r15 = current x-position
  mov r14, 0 ; r14 = current y-position
  mov r11, 0 ; r11 = min x-position
  mov r10, 0 ; r10 = min y-position
  mov r9, 0 ; r9 = max x-position
  mov r8, 0; r8 = max y-position
  mov rsi, r12
.boundsLoop:
  cmp rsi, r13
  jnl .endBoundsLoop

  lea rdi, [r14 + 1]
  cmp BYTE [rsi], 'U'
  cmove r14, rdi
  je .continueBoundsLoop

  lea rdi, [r14 - 1]
  cmp BYTE [rsi], 'D'
  cmove r14, rdi
  je .continueBoundsLoop

  lea rdi, [r15 - 1]
  cmp BYTE [rsi], 'L'
  cmove r15, rdi
  je .continueBoundsLoop

  inc r15 ; must be moving right

.continueBoundsLoop:

  ; r15 < r11 ? r11 = r15
  cmp r15, r11
  cmovl r11, r15
  ; r15 > r9 ? r9 = r15
  cmp r15, r9
  cmovg r9, r15
  ; r14 < r10 ? r10 = r14
  cmp r14, r10
  cmovl r10, r14
  ; r14 > r8 ? r8 = r14
  cmp r14, r8
  cmovg r8, r14

  inc rsi

  jmp .boundsLoop
.endBoundsLoop:

  mov r15, r11
  neg r15 ; r15 = starting x-value
  mov r14, r10
  neg r14 ; r14 = starting y-value
  sub r9, r11
  inc r9 ; r9 = width
  sub r8, r10
  inc r8 ; r8 = height

  mov rdi, r9
  imul rdi, r8
  ; shl rdi, 0 ; allocate bytes
  mov rbp, rdi ; rbp = length of pixels
  call alloc
  mov rbx, rax ; rbx = pixels in row-major order
  add rbp, rbx ; rbp = end of pixels

  ; mov r15, r15 ; r15 = head x-value
  ; mov r14, r14 ; r14 = head y-value
  mov r11, r15 ; r11 = tail x-value
  mov r10, r14 ; r10 = tail y-value

  mov rdi, r14
  imul rdi, r9
  add rdi, r15 ; rdi = starting position

  or BYTE [rbx + rdi], 0x1 ; mark as visited

  ; for (r12; r12 < r13; ++r12)
.moveLoop:
  cmp r12, r13
  jnl .endMoveLoop

  ; coherence check
  ; head.x < width
  cmp r15, r9
  jl .headXMaxCoherent
  ud2
.headXMaxCoherent:
  ; head.x >= 0
  cmp r15, 0
  jge .headXMinCoherent
  ud2
.headXMinCoherent:
  ; head.y < height
  cmp r14, r8
  jl .headYMaxCoherent
  ud2
.headYMaxCoherent:
  ; head.y >= 0
  cmp r14, 0
  jge .headYMinCoherent
  ud2
.headYMinCoherent:
  ; tail.x < width
  cmp r11, r9
  jl .tailXMaxCoherent
  ud2
.tailXMaxCoherent:
  ; tail.x >= 0
  cmp r11, 0
  jge .tailXMinCoherent
  ud2
.tailXMinCoherent:
  ; tail.y < height
  cmp r10, r8
  jl .tailYMaxCoherent
  ud2
.tailYMaxCoherent:
  ; tail.y >= 0
  cmp r10, 0
  jge .tailYMinCoherent
  ud2
.tailYMinCoherent:

  ; move head

  ; up
  lea rdi, [r14 + 1]
  cmp BYTE [r12], 'U'
  cmove r14, rdi
  je .doneHeadMove

  ; down
  lea rdi, [r14 - 1]
  cmp BYTE [r12], 'D'
  cmove r14, rdi
  je .doneHeadMove

  ; left
  lea rdi, [r15 - 1]
  cmp BYTE [r12], 'L'
  cmove r15, rdi
  je .doneHeadMove

  ; right
  inc r15

.doneHeadMove:

  ; move tail
  ; diagram below shows moves
  ;    --
  ;    21012
  ;  2 \\|//
  ;  1 \   /
  ;  0 - H -
  ; -1 /   \
  ; -2 //|\\

  ; for reference:
  ; r15 = head x-value
  ; r14 = head y-value
  ; r11 = tail x-value
  ; r10 = tail y-value

  mov rdi, r10
  sub rdi, r14
  add rdi, 2
  mov rax, 5
  imul rdi, rax

  mov rsi, r11
  sub rsi, r15
  add rsi, 2
  add rsi, rdi ; rsi = jump table index

  jmp [tailMoveJumpTable + rsi * 8]

..@tailUpLeft:
  inc r11
  dec r10
  jmp ..@doneTailMove

..@tailUp:
  dec r10
  jmp ..@doneTailMove

..@tailUpRight:
  dec r11
  dec r10
  jmp ..@doneTailMove

..@tailLeft:
  inc r11
  jmp ..@doneTailMove

..@tailRight:
  dec r11
  jmp ..@doneTailMove

..@tailDownLeft:
  inc r11
  inc r10
  jmp ..@doneTailMove

..@tailDown:
  inc r10
  jmp ..@doneTailMove

..@tailDownRight:
  dec r11
  inc r10
  jmp ..@doneTailMove

..@doneTailMove:

  ; record visited status
  mov rdi, r10
  imul rdi, r9
  add rdi, r11
  or BYTE [rbx + rdi], 0x1 ; mark as visited

  inc r12

  jmp .moveLoop
.endMoveLoop:

  ; count number of spaces with visited bit set
  mov rcx, rbp
  sub rcx, rbx
  mov rsi, rbx
  mov rdi, 0
  mov ah, 0
.countLoop:

  lodsb
  lea rbx, [rdi + 1]
  bt ax, 0
  cmovc rdi, rbx

  loop .countLoop

  call putlong
  call newline

  mov dil, 0
  call exit

section .rodata
tailMoveJumpTable:
  dq ..@tailDownLeft
  dq ..@tailDownLeft
  dq ..@tailDown
  dq ..@tailDownRight
  dq ..@tailDownRight

  dq ..@tailDownLeft
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@tailDownRight

  dq ..@tailLeft
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@tailRight

  dq ..@tailUpLeft
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@doneTailMove
  dq ..@tailUpRight

  dq ..@tailUpLeft
  dq ..@tailUpLeft
  dq ..@tailUp
  dq ..@tailUpRight
  dq ..@tailUpRight