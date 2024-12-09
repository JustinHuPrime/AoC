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
  mov rax, -1
  rep stosq
  mov currBlock, rdi

  mov currMode, 1

.continueReadLoop:

  inc currChar

  cmp BYTE [currChar], `\n`
  jne .readLoop

  ; move stuff
  lea rsi, [disk + 8 * (DISK_SIZE - 1)] ; rsi = where to move from
  mov rdx, -1 ; rdx = highest ID not to be moved/last moved id
.moveLoop:

  ; adjust rsi
.findSourceLoop:
  ; find next thing to the left of this that's < last moved id
  cmp [rsi], rdx
  jb .endFindSourceLoop

  sub rsi, 8

  jmp .findSourceLoop
.endFindSourceLoop:
  ; update last moved id
  mov rdx, [rsi]

  ; move left by the file size
  mov r8, 1 ; r8 = file size
.findSourceStartLoop:
  cmp [rsi - 8], rdx
  jne .endFindSourceStartLoop

  sub rsi, 8
  inc r8

  jmp .findSourceStartLoop
.endFindSourceStartLoop:

  ; find a space that might fit this
  mov rdi, disk
.findDestinationLoop:
  cmp rdi, rsi
  jae .continueMoveLoop ; can't move this file
  cmp QWORD [rdi], -1
  jne .continueFindDestinationLoop ; can't move to here

  ; this is the start of an empty space - how long is it
  mov r9, 1 ; r9 = space size
  mov r10, rdi
.checkDestinationSizeLoop:
  cmp QWORD [r10 + 8], -1
  jne .endCheckDestinationSizeLoop

  add r10, 8
  inc r9

  jmp .checkDestinationSizeLoop
.endCheckDestinationSizeLoop:

  cmp r9, r8 ; is this space is large enough
  jae .endFindDestinationLoop ; found it!

.continueFindDestinationLoop:

  add rdi, 8

  jmp .findDestinationLoop
.endFindDestinationLoop:

  ; do move
  
  ; mov rdi, rdi
  mov rcx, r8
  mov rax, rdx
  rep stosq

  mov rdi, rsi
  mov rcx, r8
  mov rax, -1
  rep stosq

.continueMoveLoop:

  cmp rsi, disk
  ja .moveLoop

  ; calculate checksum
  mov accumulator, 0
  mov currBlock, disk
.checksumLoop:
  cmp QWORD [currBlock], -1
  je .continueChecksumLoop

  mov rax, currBlock
  sub rax, disk
  shr rax, 3
  mul QWORD [currBlock]

  add accumulator, rax

.continueChecksumLoop:
  add currBlock, 8

  cmp currBlock, disk + 8 * DISK_SIZE
  jb .checksumLoop
.endChecksumLoop:

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .data
dq -1 ; padding for disk
disk: times DISK_SIZE dq -1
