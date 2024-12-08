extern exit, mmap, putlong, newline

section .text

%define endOfFile r12
%define currChar r13
%define accumulator r14
%define currCell r15
%define length r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; read grid
  mov currCell, grid
.readLoop:

  mov length, 0
.readLineLoop:

  mov al, [currChar]
  mov [currCell], al

  inc currChar
  inc currCell
  inc length

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  and currCell, ~127
  add currCell, 128

  cmp currChar, endOfFile
  jb .readLoop

  ; compute antinodes
  mov rdi, grid ; rdi = first antenna index
.computeFirstLoop:

  cmp BYTE [rdi], '.'
  je .continueFirstLoop
  cmp BYTE [rdi], 0
  je .continueFirstLoop

  lea rsi, [rdi + 1] ; rsi = second antenna index
.computeSecondLoop:

  mov al, [rdi]
  cmp [rsi], al
  jne .continueSecondLoop

  ; rdi and rsi form a pair
  ; antinode set 1 = rsi + n * (rsi - rdi)
  ; antinode 2 = rdi + n * (rdi - rsi)

  mov rax, rsi
.checkFirstLoop:

  ; if rax < grid
  cmp rax, grid
  jl .checkOther
  ; if rax >= grid + 128 * length
  mov rdx, length
  shl rdx, 7
  add rdx, grid
  cmp rax, rdx
  jge .checkOther
  ; if rax & 127 > length
  mov rdx, rax
  and rdx, 127
  cmp rdx, length
  jge .checkOther

  inc BYTE [rax - grid + antinodes]

  add rax, rsi
  sub rax, rdi

  jmp .checkFirstLoop

.checkOther:

  mov rax, rdi
.checkSecondLoop:

  ; if rax < grid
  cmp rax, grid
  jl .continueSecondLoop
  ; if rax >= grid + 128 * length
  mov rdx, length
  shl rdx, 7
  add rdx, grid
  cmp rax, rdx
  jge .continueSecondLoop
  ; if rax & 127 > length
  mov rdx, rax
  and rdx, 127
  cmp rdx, length
  jge .continueSecondLoop

  inc BYTE [rax - grid + antinodes]

  add rax, rdi
  sub rax, rsi

  jmp .checkSecondLoop

.continueSecondLoop:
  inc rsi

  cmp rsi, grid + 128 * 128
  jb .computeSecondLoop

.continueFirstLoop:
  inc rdi

  cmp rdi, grid + 128 * 128
  jb .computeFirstLoop
  
  ; count antinodes
  mov currCell, antinodes
  mov accumulator, 0
.countLoop:

  cmp BYTE [currCell], 0
  je .continueCountLoop

  inc accumulator

.continueCountLoop:

  inc currCell

  cmp currCell, antinodes + 128 * 128
  jb .countLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
alignb 128
grid: resb 128 * 128
alignb 128
antinodes: resb 128 * 128
