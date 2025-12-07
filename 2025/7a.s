extern mmap, putlong, newline, exit, countc, findc, alloc

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define width r13
%define height r14
%define map r15
%define mapEnd rbx
%define accumulator r12

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
  mov mapEnd, rdi
  call alloc
  mov map, rax
  add mapEnd, rax

  ; read input
  mov rdi, 0
.readLoop:

  ; read a row
.readRowLoop:

  mov al, [currChar]
  mov sil, '|'
  cmp al, `S`
  cmove rax, rsi
  mov [map + rdi], al

  inc currChar
  inc rdi

  cmp BYTE [currChar], `\n`
  jne .readRowLoop

  inc currChar

  cmp currChar, endOfFile
  jb .readLoop

  ; do simulation row by row
  lea rdi, [map + width]
  mov accumulator, 0
.simLoop:

  mov rsi, 1
.simCellLoop:

  lea rdx, [rdi + rsi]
  sub rdx, width

  mov al, [rdi + rsi] ; al = this cell
  mov cl, [rdx] ; cl = cell above
  cmp al, '.'
  jne .notEmpty

  cmp cl, '|'
  jne .continueSimCellLoop

  mov BYTE [rdi + rsi], '|' ; beam proceeds down

  jmp .continueSimCellLoop
.notEmpty:
  ; has to be a splitter

  cmp cl, '|'
  jne .continueSimCellLoop

  mov BYTE [rdi + rsi - 1], '|' ; split beam
  mov BYTE [rdi + rsi + 1], '|' ; split beam
  inc accumulator ; record this hit
  inc rsi ; skip next cell - it's definitely got a beam

.continueSimCellLoop:
  inc rsi

  mov rax, rsi
  inc rax
  cmp rax, width
  jb .simCellLoop

  add rdi, width

  cmp rdi, mapEnd
  jb .simLoop

  mov rdi, accumulator
  call putlong
  call newline
  
  mov dil, 0
  call exit