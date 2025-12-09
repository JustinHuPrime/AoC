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

  ; allocate array of tiles
  mov rdi, length
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

  ; get x-difference
  mov rdx, [r10 + 0 * 8]
  sub rdx, [r11 + 0 * 8]
  mov rsi, rdx
  neg rsi
  test rdx, rdx
  cmovs rdx, rsi
  inc rdx

  ; get y-difference
  mov rax, [r10 + 1 * 8]
  sub rax, [r11 + 1 * 8]
  mov rsi, rax
  neg rsi
  test rax, rax
  cmovs rax, rsi
  inc rax

  ; multiply
  mul rdx

  ; store if larger
  cmp rax, rdi
  cmovg rdi, rax

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
