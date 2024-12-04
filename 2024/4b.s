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

  ; check current is A
  cmp BYTE [search + currLine + currCol], 'A'
  jne .notXmas

  ; copy corners into scratch as UL, UR, DL, DR
  mov al, [search + currLine + currCol - 256 - 1]
  mov [scratch + 0], al
  mov al, [search + currLine + currCol - 256 + 1]
  mov [scratch + 1], al
  mov al, [search + currLine + currCol + 256 - 1]
  mov [scratch + 2], al
  mov al, [search + currLine + currCol + 256 + 1]
  mov [scratch + 3], al
  
  mov eax, [possible1]
  cmp [scratch], eax
  je .isXmas
  mov eax, [possible2]
  cmp [scratch], eax
  je .isXmas
  mov eax, [possible3]
  cmp [scratch], eax
  je .isXmas
  mov eax, [possible4]
  cmp [scratch], eax
  je .isXmas

  jmp .notXmas
.isXmas:

  inc accumulator

.notXmas:

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

section .rodata
; M.M
; .A.
; S.S
possible1: dd 'MMSS'
; M.S
; .A.
; M.S
possible2: dd 'MSMS'
; S.M
; .A.
; S.M
possible3: dd 'SMSM'
; S.S
; .A.
; M.M
possible4: dd 'SSMM'
