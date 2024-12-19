extern exit, mmap, putlong, newline, findnl

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define accumulator r13

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
  
  mov rdi, towels
.readTowelsLoop:

  mov rsi, rdi
.readTowelLoop:

  mov al, [currChar]
  mov [rsi], al

  inc currChar
  inc rsi

  cmp BYTE [currChar], ','
  je .endReadTowelLoop
  cmp BYTE [currChar], `\n`
  je .endReadTowelLoop

  jmp .readTowelLoop
.endReadTowelLoop:

  add rdi, 16
  add currChar, 2

  cmp BYTE [currChar - 1], `\n`
  jne .readTowelsLoop

  mov accumulator, 0
.countLoop:

  mov rdi, currChar
  call canMake
  lea rdx, [accumulator + 1]
  test al, al
  cmovnz accumulator, rdx

  mov rdi, currChar
  call findnl
  lea currChar, [rax + 1]

  cmp currChar, endOfFile
  jb .countLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; template as inlined-looped-mutual-ref backtracking search
;; rdi = design to make
canMake:
  ; base case - if design to make is empty, yes, we can trivially make it
  cmp BYTE [rdi], `\n`
  je .true

  ; inlined looped recursive case - backtrack search through possible next towels
  mov rsi, towels
.tryTowelLoop:
  ; base case - if no towels left to try, no, we can't make it
  cmp BYTE [rsi], 0
  je .false

  ; recursive case - try this towel
  sub rsp, 2 * 8
  mov [rsp + 0 * 8], rdi ; save design to make
  mov [rsp + 1 * 8], rsi ; save towel to try

  ; does this towel even fit here?
  ; mov rdi, rdi ; compare design to make
  ; mov rsi, rsi ; with towel to try
  mov rcx, 16 ; rcx shouldn't matter
  repe cmpsb ; compare strings
  dec rsi
  dec rdi
  cmp BYTE [rsi], 0 ; did this match the whole towel?
  jne .continueTryTowelLoop
  
  ; recurse
  call canMake
  test al, al
  jz .continueTryTowelLoop

  add rsp, 2 * 8
  ret

.continueTryTowelLoop:
  mov rdi, [rsp + 0 * 8]
  mov rsi, [rsp + 1 * 8]
  add rsp, 2 * 8

  add rsi, 16
  jmp .tryTowelLoop

.true:
  mov al, 1
  ret
.false:
  mov al, 0
  ret

section .bss
;; char towels[16][256]
;; null terminated char strings
towels: resb 16 * 512