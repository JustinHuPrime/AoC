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
  mov r15d, 0 ; r15 = current x-position
  mov r14d, 0 ; r14 = current y-position
  mov r11d, 0 ; r11 = min x-position
  mov r10d, 0 ; r10 = min y-position
  mov r9d, 0 ; r9 = max x-position
  mov r8d, 0; r8 = max y-position
  mov rsi, r12
.boundsLoop:
  cmp rsi, r13
  jnl .endBoundsLoop

  lea edi, [r14d + 1]
  cmp BYTE [rsi], 'U'
  cmove r14d, edi
  je .continueBoundsLoop

  lea edi, [r14d - 1]
  cmp BYTE [rsi], 'D'
  cmove r14d, edi
  je .continueBoundsLoop

  lea edi, [r15d - 1]
  cmp BYTE [rsi], 'L'
  cmove r15d, edi
  je .continueBoundsLoop

  inc r15d ; must be moving right

.continueBoundsLoop:

  ; r15 < r11 ? r11 = r15
  cmp r15d, r11d
  cmovl r11d, r15d
  ; r15 > r9 ? r9 = r15
  cmp r15d, r9d
  cmovg r9d, r15d
  ; r14 < r10 ? r10 = r14
  cmp r14d, r10d
  cmovl r10d, r14d
  ; r14 > r8 ? r8 = r14
  cmp r14d, r8d
  cmovg r8d, r14d

  inc rsi

  jmp .boundsLoop
.endBoundsLoop:

  mov r15d, r11d
  neg r15d ; r15 = starting x-value
  mov r14d, r10d
  neg r14d ; r14 = starting y-value
  sub r9d, r11d
  inc r9d ; r9 = width
  sub r8d, r10d
  inc r8d ; r8 = height

  mov edi, r9d
  imul edi, r8d
  ; shl edi, 0 ; allocate bytes
  mov ebp, edi ; rbp = length of pixels
  ; movzx rbp, ebp
  call alloc
  mov rbx, rax ; rbx = pixels in row-major order
  add rbp, rbx ; rbp = end of pixels

  sub rsp, 4 * 2 * 10 ; allocate 4 * 2 * 10 bytes for rope coordinates
  mov rcx, 10
  mov rsi, rsp
.fillCoordsLoop:

  mov [rsi + 0], r15d
  mov [rsi + 4], r14d
  add rsi, 2 * 4

  loop .fillCoordsLoop

  mov edi, r14d
  imul edi, r9d
  add edi, r15d ; rdi = starting position
  ; movzx rdi, edi

  or BYTE [rbx + rdi], 0x1 ; mark as visited

  ; for (r12; r12 < r13; ++r12)
.moveLoop:
  cmp r12, r13
  jnl .endMoveLoop

  ; move head
  mov r15d, [rsp + 0 * 8 + 0]
  mov r14d, [rsp + 0 * 8 + 4]

  ; up
  lea edi, [r14d + 1]
  cmp BYTE [r12], 'U'
  cmove r14d, edi
  je .doneHeadMove

  ; down
  lea edi, [r14d - 1]
  cmp BYTE [r12], 'D'
  cmove r14d, edi
  je .doneHeadMove

  ; left
  lea edi, [r15d - 1]
  cmp BYTE [r12], 'L'
  cmove r15d, edi
  je .doneHeadMove

  ; right
  inc r15d

.doneHeadMove:

  mov [rsp + 0 * 8 + 0], r15d
  mov [rsp + 0 * 8 + 4], r14d

  ; invariants:
  ; r15d = parent link's x
  ; r14d = parent link's y
  ; r11d = this link's x
  ; r10d = this link's y
  ; rdx = this link's offset
  ; for (rdx = 1; rdx < 10; ++rdx)
  mov rdx, 1
.linkLoop:
  cmp rdx, 10
  jnl .endLinkLoop

  ; get this link's coordinates
  mov r11d, [rsp + rdx * 8 + 0]
  mov r10d, [rsp + rdx * 8 + 4]

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

  mov edi, r10d
  sub edi, r14d
  add edi, 2
  mov eax, 5
  imul edi, eax

  mov esi, r11d
  sub esi, r15d
  add esi, 2
  add esi, edi ; rsi = jump table index

  ; movzx rsi, esi
  mov rax, [tailMoveJumpTable + rsi * 8]
  jmp rax

..@tailUpLeft:
  inc r11d
  dec r10d
  jmp ..@doneTailMove

..@tailUp:
  dec r10d
  jmp ..@doneTailMove

..@tailUpRight:
  dec r11d
  dec r10d
  jmp ..@doneTailMove

..@tailLeft:
  inc r11d
  jmp ..@doneTailMove

..@tailRight:
  dec r11d
  jmp ..@doneTailMove

..@tailDownLeft:
  inc r11d
  inc r10d
  jmp ..@doneTailMove

..@tailDown:
  inc r10d
  jmp ..@doneTailMove

..@tailDownRight:
  dec r11d
  inc r10d
  jmp ..@doneTailMove

..@doneTailMove:

  ; store this link's coordinates
  mov [rsp + rdx * 8 + 0], r11d
  mov [rsp + rdx * 8 + 4], r10d

  ; copy this link's coordinates to parent's coordinates
  mov r15d, r11d
  mov r14d, r10d
  
  inc rdx

  jmp .linkLoop
.endLinkLoop:

  ; record visited status for last link
  mov edi, r10d
  imul edi, r9d
  add edi, r11d
  ; movzx rdi, edi
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