extern mmap, putlong, newline, exit, countc, alloc, findc, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define length r13
%define tiles r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  ; count number of tiles
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, `\n`
  call countc
  mov length, rax

  ; allocate array of tiles (plus one for wraparound)
  mov rdi, length
  inc rdi
  shl rdi, 4
  call alloc
  mov tiles, rax

  ; parse input
  mov r15, tiles ; r15 = current tile
.readLoop:

  ; parse first number
  mov rdi, currChar
  mov sil, ','
  call findc
  
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [r15 + 0 * 8], rax

  inc currChar

  ; parse second number
  mov rdi, currChar
  mov sil, `\n`
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [r15 + 1 * 8], rax

  inc currChar
  add r15, 2 * 8

  cmp currChar, endOfFile
  jb .readLoop

  mov rsi, tiles
  mov rdi, length
  shl rdi, 4
  add rdi, tiles
  mov rcx, 2
  rep movsq

  ; check each pair
  mov rdi, 0 ; rdi = largest area so far
  mov r8, 0 ; r8 = first tile index
.checkPairLoop:

  mov r10, r8
  shl r10, 4
  add r10, tiles ; r10 = first tile pointer

  lea r9, [r8 + 1] ; r9 = second tile index
.checkPairInnerLoop:

  mov r11, r9
  shl r11, 4
  add r11, tiles ; r11 = second tile pointer

  ; get smallest and largest x
  mov rax, [r10 + 0 * 8]
  mov rbx, [r11 + 0 * 8]
  cmp rax, rbx
  jbe .noSwapX
  xchg rax, rbx
.noSwapX:

  ; get smallest and largest y
  mov rcx, [r10 + 1 * 8]
  mov rdx, [r11 + 1 * 8]
  cmp rcx, rdx
  jbe .noSwapY
  xchg rcx, rdx
.noSwapY:

  ; check - are there any red tiles strictly inside this rectangle?
  mov r12, 0
.checkLoop:

  mov rsi, r12
  shl rsi, 4
  add rsi, tiles

  ; case - entirely contained
  cmp rax, [rsi + 0 * 8]
  jae .notEntirelyContained
  cmp rbx, [rsi + 0 * 8]
  jbe .notEntirelyContained
  cmp rcx, [rsi + 1 * 8]
  jae .notEntirelyContained
  cmp rdx, [rsi + 1 * 8]
  jbe .notEntirelyContained

  jmp .continue

.notEntirelyContained:

  ; case - if this point is within the x-range of the polygon
  cmp rax, [rsi + 0 * 8]
  jae .cantSplitVertically
  cmp rbx, [rsi + 0 * 8]
  jbe .cantSplitVertically

  ; if y-min >= point, the next point must be too
  ; if y-max >= point, the next point must be too
  cmp rcx, [rsi + 1 * 8]
  setae bpl
  cmp rcx, [rsi + 16 + 1 * 8]
  setae r15b
  cmp bpl, r15b
  jne .continue

.cantSplitVertically:

  ; case - if this point is within the y-range of the polygon
  cmp rcx, [rsi + 1 * 8]
  jae .cantSplitHorizontally
  cmp rdx, [rsi + 1 * 8]
  jbe .cantSplitHorizontally

  ; if x-min >= point, the next point must be too
  ; if x-max >= point, the next point must be too
  cmp rax, [rsi + 0 * 8]
  setae bpl
  cmp rax, [rsi + 16 + 0 * 8]
  setae r15b
  cmp bpl, r15b
  jne .continue

.cantSplitHorizontally:

  inc r12

  cmp r12, length
  jb .checkLoop

  ; get x-difference
  sub rbx, rax
  inc rbx

  ; get y-difference
  sub rdx, rcx
  inc rdx

  ; multiply
  mov rax, rbx
  mul rdx

  ; store if larger
  cmp rax, rdi
  cmovg rdi, rax

.continue:
  inc r9

  cmp r9, length
  jb .checkPairInnerLoop

  inc r8
  lea rax, [r8 + 1]
  cmp rax, length
  jb .checkPairLoop

  ; mov rdi, rdi
  call putlong
  call newline

  mov dil, 0
  call exit
