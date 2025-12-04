extern mmap, putlong, newline, exit, findnl, alloc

section .text

%define currChar r12
%define endOfFile r13
%define map r14
%define accumulator r15
%define size rbx
%define mapEnd rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; figure out the size of the map
  mov rdi, currChar
  call findnl
  sub rax, currChar ; rax = size without padding
  lea size, [rax + 2] ; rbx = size with padding

  ; allocate the map
  mov rax, size
  mul size
  mov rdi, rax
  mov mapEnd, rax
  call alloc
  mov map, rax
  add mapEnd, rax

  ; load data
  lea rcx, [map + size + 1]
.loadLoop:

.loadLineLoop:
  ; load the current character
  mov al, [currChar]
  mov dil, 0
  mov sil, 1
  cmp al, '@'
  cmove rdi, rsi
  mov [rcx], dil

  ; move to next position
  inc currChar
  inc rcx

  cmp BYTE [currChar], `\n`
  jne .loadLineLoop

  ; move to next line
  inc currChar
  add rcx, 2

  cmp currChar, endOfFile
  jb .loadLoop

  ; scan through the map
  mov accumulator, 0
  lea rdi, [map + size] ; rdi = row offset
.scanLoop:

  mov rsi, 1 ; rsi = column offset
.scanLineLoop:

  lea rdx, [rdi + rsi]
  mov al, [rdx] ; al = contents of current cell
  test al, al
  jz .continueScanLineLoop ; if not occupied, bail

  ; get sum of eight neighbouring cells
  sub rdx, size
  mov al, [rdx - 1]
  add al, [rdx]
  add al, [rdx + 1]
  add rdx, size
  add al, [rdx - 1]
  add al, [rdx + 1]
  add rdx, size
  add al, [rdx - 1]
  add al, [rdx]
  add al, [rdx + 1]

  ; 4 or more rolls -> too many, bail
  cmp al, 4
  jae .continueScanLineLoop

  inc accumulator

.continueScanLineLoop:
  inc rsi

  cmp rsi, size
  jb .scanLineLoop

  add rdi, size

  cmp rdi, mapEnd
  jb .scanLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit