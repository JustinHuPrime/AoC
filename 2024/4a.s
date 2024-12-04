extern exit, mmap, putlong, newline, atol, findnl

section .text

%define endOfFile r12
%define currChar r13
%define currLine r14
%define currCol r15
%define accumulator r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; read input into search
  mov currLine, 256 * 3 ; 3 lines of padding
.readLoop:

  mov currCol, 3 ; 3 characters of padding
.readLineLoop:

  mov al, [currChar]
  mov [search + currLine + currCol], al

  inc currChar
  inc currCol

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  add currLine, 256

  cmp currChar, endOfFile
  jb .readLoop

  ; do search
  mov accumulator, 0
  mov currLine, 256 * 3
.searchLoop:

  mov currCol, 3
.searchLineLoop:

  ; check up
  mov al, [search + currLine + currCol - 0 * 256]
  mov [scratch + 0], al
  mov al, [search + currLine + currCol - 1 * 256]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol - 2 * 256]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol - 3 * 256]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notUp

  inc accumulator

.notUp:
  ; check up-right
  ; mov al, [search + currLine + currCol - 0 * 256 + 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol - 1 * 256 + 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol - 2 * 256 + 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol - 3 * 256 + 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notUpRight

  inc accumulator

.notUpRight:
  ; check right
  ; mov al, [search + currLine + currCol + 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol + 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol + 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol + 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notRight

  inc accumulator

.notRight:
  ; check down-right
  ; mov al, [search + currLine + currCol + 0 * 256 + 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol + 1 * 256 + 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol + 2 * 256 + 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol + 3 * 256 + 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notDownRight

  inc accumulator

.notDownRight:
  ; check down
  ; mov al, [search + currLine + currCol + 0 * 256]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol + 1 * 256]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol + 2 * 256]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol + 3 * 256]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notDown

  inc accumulator

.notDown:
  ; check down-left
  ; mov al, [search + currLine + currCol + 0 * 256 - 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol + 1 * 256 - 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol + 2 * 256 - 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol + 3 * 256 - 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notDownLeft

  inc accumulator

.notDownLeft:
  ; check left
  ; mov al, [search + currLine + currCol - 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol - 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol - 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol - 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notLeft

  inc accumulator

.notLeft:
  ; check up-left
  ; mov al, [search + currLine + currCol - 0 * 256 - 0]
  ; mov [scratch + 0], al
  mov al, [search + currLine + currCol - 1 * 256 - 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol - 2 * 256 - 2]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol - 3 * 256 - 3]
  mov [scratch + 3], al
  cmp DWORD [scratch], 'XMAS'
  jne .notUpLeft

  inc accumulator

.notUpLeft:

  inc currCol

  cmp BYTE [search + currLine + currCol], 0
  jne .searchLineLoop

  add currLine, 256

  cmp BYTE [search + currLine + 3], 0
  jne .searchLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
search: resb 256 * 256
scratch: resb 4
