extern mmap, exit, putlong, newline, alloc, findnl, countc

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  ; get shape of input
  mov rdi, r15
  call findnl
  sub rax, r15
  mov r13, rax ; r13 = width of input

  mov rdi, r15
  mov rsi, r14
  mov dl, 0xa
  call countc
  mov r12, rax ; r12 = height of input

  mov rbx, r12
  imul rbx, r13 ; rbx = size of input

  mov rdi, rbx
  call alloc
  mov r8, rax ; r8 = input array

  mov rdi, rbx
  call alloc
  mov r9, rax ; r9 = visibility array

  ; read input, into row-major order (array[x, y] = array[x + width * y])
  mov rax, 0 ; rax = current index
.readLoop:
  cmp r15, r14
  jnl .endReadLoop

  ; skip if this is a newline
  mov dl, [r15]
  cmp dl, 0xa
  je .continueReadLoop

  mov [r8 + rax], dl
  inc rax

.continueReadLoop:
  inc r15

  jmp .readLoop
.endReadLoop:

  ; add to visibility array for visibility from above
  ; for (rax = 0; rax < width; ++rax)
  mov rax, 0
.visibleAboveLoop:
  cmp rax, r13
  jnl .endVisibleAboveLoop

  mov sil, -1 ; sil = highest tree seen so far
  ; for (rdx = 0; rdx < height; ++rdx)
  mov rdx, 0
.visibleAboveColumnLoop:
  cmp rdx, r12
  jnl .endVisibleAboveColumnLoop

  mov rdi, rdx
  imul rdi, r13
  add rdi, rax ; rdi = array offset

  ; if trees[rdi] > highest, visible[rdi] |= 0x1, highest = trees[rdi]
  cmp [r8 + rdi], sil
  jng .notVisibleAbove

  or BYTE [r9 + rdi], 0x1
  mov sil, [r8 + rdi]

.notVisibleAbove:

  inc rdx

  jmp .visibleAboveColumnLoop
.endVisibleAboveColumnLoop:

  inc rax

  jmp .visibleAboveLoop
.endVisibleAboveLoop:

  ; add to visibility array for visibility from below
  ; for (rax = 0; rax < width; ++rax)
  mov rax, 0
.visibleBelowLoop:
  cmp rax, r13
  jnl .endVisibleBelowLoop

  mov sil, -1 ; sil = highest tree seen so far
  ; for (rdx = height; rdx > 0; --rdx)
  mov rdx, r12
.visibleBelowColumnLoop:
  cmp rdx, 0
  jng .endVisibleBelowColumnLoop

  mov rdi, rdx
  dec rdi
  imul rdi, r13
  add rdi, rax

  ; if trees[rdi] > highest, visible[rdi] |= 0x2, highest = trees[rdi]
  cmp [r8 + rdi], sil
  jng .notVisibleBelow

  or BYTE [r9 + rdi], 0x2
  mov sil, [r8 + rdi]

.notVisibleBelow:

  dec rdx

  jmp .visibleBelowColumnLoop
.endVisibleBelowColumnLoop:

  inc rax

  jmp .visibleBelowLoop
.endVisibleBelowLoop:

  ; add to visibility array for visibility from left
  ; for (rdx = 0; rdx < height; ++rdx)
  mov rdx, 0
.visibleLeftLoop:
  cmp rdx, r12
  jnl .endVisibleLeftLoop

  mov sil, -1 ; sil = highest tree seen so far
  ; for (rax = 0; rax < width; ++rax)
  mov rax, 0
.visibleLeftRowLoop:
  cmp rax, r13
  jnl .endVisibleLeftRowLoop

  mov rdi, rdx
  imul rdi, r13
  add rdi, rax ; rdi = array offset

  ; if trees[rdi] > highest, visible[rdi] |= 0x4, highest = trees[rdi]
  cmp [r8 + rdi], sil
  jng .notVisibleLeft

  or BYTE [r9 + rdi], 0x4
  mov sil, [r8 + rdi]

.notVisibleLeft:

  inc rax

  jmp .visibleLeftRowLoop
.endVisibleLeftRowLoop:

  inc rdx

  jmp .visibleLeftLoop
.endVisibleLeftLoop:

  ; add to visibility array for visibility from right
  ; for (rdx = 0; rdx < height; ++rdx)
  mov rdx, 0
.visibleRightLoop:
  cmp rdx, r12
  jnl .endVisibleRightLoop

  mov sil, -1 ; sil = highest tree seen so far
  ; for (rax = width; rax > 0; --rax)
  mov rax, r13
.visibleRightRowLoop:
  cmp rax, 0
  jng .endVisibleRightRowLoop

  mov rdi, rdx
  imul rdi, r13
  add rdi, rax
  dec rdi

  ; if trees[rdi] > highest, visible[rdi] |= 0x8, highest = trees[rdi]
  cmp [r8 + rdi], sil
  jng .notVisibleRight

  or BYTE [r9 + rdi], 0x8
  mov sil, [r8 + rdi]

.notVisibleRight:

  dec rax

  jmp .visibleRightRowLoop
.endVisibleRightRowLoop:

  inc rdx

  jmp .visibleRightLoop
.endVisibleRightLoop:

  ; count number of nonzero bytes in array
  mov rcx, rbx
  mov rsi, r9
  mov rdi, 0 ; rdi = count of nonzero bytes
.countLoop:

  lea rdx, [rdi + 1]
  lodsb
  test al, al
  cmovnz rdi, rdx

  loop .countLoop

  call putlong
  call newline

  mov dil, 0
  call exit