extern mmap, putlong, newline, exit, countc, findc, alloc

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define width r13
%define height r14
%define map r15
%define mapEnd rbx

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

  ; count number of columns
  mov rdi, currChar
  mov sil, `\n`
  call findc
  sub rax, currChar
  mov width, rax

  ; count number of rows
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, `\n`
  call countc
  mov height, rax

  ; allocate map
  mov rax, width
  mul height
  mov rdi, rax
  shl rdi, 3
  mov mapEnd, rdi
  call alloc
  mov map, rax
  add mapEnd, rax

  ; read input
  mov rdi, 0
.readLoop:

  ; read a row
.readRowLoop:

  mov al, BYTE [currChar]
  cmp al, 'S'
  jne .notStart

  mov rax, 1
  mov [map + 8 * rdi], rax

  jmp .continueRead
.notStart:

  cmp al, '^'
  jne .continueRead

  mov rax, -1
  mov [map + 8 * rdi], rax

.continueRead:

  inc currChar
  inc rdi

  cmp BYTE [currChar], `\n`
  jne .readRowLoop

  inc currChar

  cmp currChar, endOfFile
  jb .readLoop

  ; do simulation row by row
  lea rdi, [map + 8 * width]
.simLoop:

  mov rsi, 0
.simCellLoop:

  mov rdx, width
  shl rdx, 3
  neg rdx
  lea rax, [rdi + 8 * rsi]
  add rdx, rax

  mov rax, [rdi + 8 * rsi] ; rax = this cell
  mov rcx, [rdx] ; rcx = cell above
  cmp rcx, -1
  je .continueSimCellLoop
  cmp rax, -1
  jne .notSplitter

  add [rdi + 8 * rsi - 8], rcx
  add [rdi + 8 * rsi + 8], rcx

  jmp .continueSimCellLoop
.notSplitter:

  add [rdi + 8 * rsi], rcx

.continueSimCellLoop:
  inc rsi

  cmp rsi, width
  jb .simCellLoop

.endSimLoop:
  lea rdi, [rdi + 8 * width]

  cmp rdi, mapEnd
  jb .simLoop

  ; add up last row of map
  mov rax, height
  dec rax
  mul width
  shl rax, 3
  add rax, map
  mov rdi, 0
.totalLoop:

  add rdi, [rax]
  add rax, 8

  cmp rax, mapEnd
  jb .totalLoop

  ; mov rdi, rdi
  call putlong
  call newline
  
  mov dil, 0
  call exit