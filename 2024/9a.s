extern exit, mmap, putlong, newline

section .text

%define DISK_SIZE 262144
%define currChar r12
%define currBlock r13
%define currMode r14
%define currId r15
%define accumulator r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax

  ; fill disk with fullptr (i.e. nonallocated bytes)
  mov rax, [fullptr]
  mov rcx, DISK_SIZE
  mov rdi, disk
  rep stosq

  ; read disk
  mov currMode, 1
  mov currBlock, disk
  mov currId, 0
.readLoop:

  mov cl, [currChar]
  sub cl, '0' ; al = number of bytes for this file or gap
  movzx rcx, cl

  test currMode, currMode
  jz .readGap
  ; read a file

  mov rdi, currBlock
  ; mov rcx, rcx
  mov rax, currId
  rep stosq
  mov currBlock, rdi

  mov currMode, 0
  inc currId

  jmp .continueReadLoop
.readGap:

  mov rdi, currBlock
  ; mov rcx, rcx
  mov rax, [fullptr]
  rep stosq
  mov currBlock, rdi

  mov currMode, 1

.continueReadLoop:

  inc currChar

  cmp BYTE [currChar], `\n`
  jne .readLoop

  ; move stuff
  mov rdi, disk ; rdi = where to move to
  lea rsi, [disk + 8 * (DISK_SIZE - 1)] ; rsi = where to move from
  mov rbx, [fullptr] ; rbx = fullptr constant
.moveLoop:
  ; adjust rdi and rsi
.findDesinationLoop:
  cmp [rdi], rbx
  je .endFindDestinationLoop

  add rdi, 8

  jmp .findDesinationLoop
.endFindDestinationLoop:

.findSourceLoop:
  cmp [rsi], rbx
  jne .endFindSourceLoop

  sub rsi, 8

  jmp .findSourceLoop
.endFindSourceLoop:

  cmp rdi, rsi
  jnb .endMoveLoop

  mov rax, [rsi]
  mov [rdi], rax
  mov [rsi], rbx

  jmp .moveLoop
.endMoveLoop:

  ; calculate checksum
  mov accumulator, 0
  mov currBlock, disk
.checksumLoop:
  cmp [currBlock], rbx
  je .endChecksumLoop

  mov rax, currBlock
  sub rax, disk
  shr rax, 3
  mul QWORD [currBlock]

  add accumulator, rax

  add currBlock, 8

  cmp currBlock, disk + 8 * DISK_SIZE
  jb .checksumLoop
.endChecksumLoop:

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .rodata
fullptr: dq ~0
section .bss
disk: resq DISK_SIZE
