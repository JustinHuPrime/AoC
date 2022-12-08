extern mmap, exit, putlong, newline, alloc, findnl, countc, maxlong

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
  mov r8, rax ; r8 = input array (as array of bytes)

  mov rdi, rbx
  shl rdi, 3
  call alloc
  mov r9, rax ; r9 = scenicness array (as array of qwords)

  ; initialize scenicness array with ones
  mov rcx, rbx
  mov rdi, r9
  mov rax, 1
  rep stosq

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

  ; for (rax = 0; rax < width; ++rax)
  mov rax, 0
.treeWidthLoop:
  cmp rax, r13
  jnl .endTreeWidthLoop

  ; for (rdx = 0; rdx < height; ++rdx)
  mov rdx, 0
.treeHeightLoop:
  cmp rdx, r12
  jnl .endTreeHeightLoop

  mov rdi, rdx
  imul rdi, r13
  add rdi, rax ; rdi = tree index
  
  mov r11b, [r8 + rdi] ; r11b = current tree height

  ; calculate upwards visibility
  ; for (rsi = rdi - width; rsi >= 0; rsi -= width)
  mov r10, 0 ; r10 = upwards visibility
  mov rsi, rdi
  sub rsi, r13
.upLoop:
  cmp rsi, 0
  jnge .endUpLoop

  inc r10

  ; break early if this tree blocks our view
  cmp [r8 + rsi], r11b
  jge .endUpLoop

  sub rsi, r13

  jmp .upLoop
.endUpLoop:

  imul r10, [r9 + rdi * 8] ; multiply onto running product
  mov [r9 + rdi * 8], r10

  ; calculate downwards visibility
  ; for (rsi = rdi + width; rsi < size; rsi += width)
  mov r10, 0
  mov rsi, rdi
  add rsi, r13
.downLoop:
  cmp rsi, rbx
  jnl .endDownLoop

  inc r10

  ; break early if this tree blocks our view
  cmp [r8 + rsi], r11b
  jge .endDownLoop

  add rsi, r13

  jmp .downLoop
.endDownLoop:

  imul r10, [r9 + rdi * 8] ; multiply onto running product
  mov [r9 + rdi * 8], r10

  mov rcx, rdx
  imul rcx, r13 ; rcx = current row's base
  add rcx, r8

  ; calculate right visibility
  ; for (rsi = rax + 1; rsi < width; ++rsi)
  mov r10, 0
  mov rsi, rax
  inc rsi
.rightLoop:
  cmp rsi, r13
  jnl .endRightLoop

  inc r10

  ; break early if this tree blocks our view
  cmp [rcx + rsi], r11b
  jge .endRightLoop

  inc rsi

  jmp .rightLoop
.endRightLoop:

  imul r10, [r9 + rdi * 8] ; multiply onto running product
  mov [r9 + rdi * 8], r10

  ; calculate left visibility
  ; for (rsi = rax - 1; rsi >= 0; --rsi)
  mov r10, 0
  mov rsi, rax
  dec rsi
.leftLoop:
  cmp rsi, 0
  jnge .endLeftLoop

  inc r10

  ; break early if this tree blocks our view
  cmp [rcx + rsi], r11b
  jge .endLeftLoop

  dec rsi

  jmp .leftLoop
.endLeftLoop:

  imul r10, [r9 + rdi * 8] ; multiply onto running product
  mov [r9 + rdi * 8], r10

  inc rdx

  jmp .treeHeightLoop
.endTreeHeightLoop:

  inc rax

  jmp .treeWidthLoop
.endTreeWidthLoop:

  mov rdi, r9
  lea rsi, [r9 + rbx * 8]
  call maxlong
  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit