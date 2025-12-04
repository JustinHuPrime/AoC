extern mmap, putlong, newline, exit, findnl, alloc

section .text

%define currChar r12
%define endOfFile r13
%define map r14
%define nextMap r15
%define size rbx
%define mapSize rbp

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
  mov mapSize, rax
  mov rdi, rax
  push rdi
  call alloc
  mov map, rax

  pop rdi
  call alloc
  mov nextMap, rax

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

  ; loop through
  mov rdi, 0 ; rdi = total number removed
.stepLoop:
  
  ; do a step
  mov rsi, 0 ; rsi = number removed this step
  mov r8, size ; r8 = row offset of current position
.rowLoop:

  mov r9, 1 ; r9 = column offset of current position
.columnLoop:

  ; check current cell
  lea rdx, [r8 + r9] ; rdx = offset of current

  mov cl, [map + rdx] ; copy current state forward
  mov [nextMap + rdx], cl

  ; if cell is empty, bail
  test cl, cl
  jz .continueColumnLoop

  ; get count of eight neighbouring cells
  lea r10, [map + rdx]
  sub r10, size
  mov al, [r10 - 1]
  add al, [r10]
  add al, [r10 + 1]
  add r10, size
  add al, [r10 - 1]
  add al, [r10 + 1]
  add r10, size
  add al, [r10 - 1]
  add al, [r10]
  add al, [r10 + 1]

  ; 4 or more rolls -> too many, bail
  cmp al, 4
  jae .continueColumnLoop

  ; this roll will go away
  inc rdi
  inc rsi
  mov BYTE [nextMap + rdx], 0

.continueColumnLoop:
  inc r9

  cmp r9, size
  jb .columnLoop

  add r8, size

  cmp r8, mapSize
  jb .rowLoop

  ; swap map and nextMap
  xchg map, nextMap

  test rsi, rsi
  jnz .stepLoop

  ; mov rdi, rdi
  call putlong
  call newline

  mov dil, 0
  call exit