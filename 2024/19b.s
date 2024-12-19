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

  mov rax, 0
  mov rdi, target
  mov rcx, 128
  rep stosb
  
  mov rax, -1
  mov rdi, memoize
  mov rcx, 128
  rep stosq

  mov rdi, currChar
  call findnl
  mov rcx, rax
  sub rcx, rdi

  mov rsi, currChar
  lea currChar, [rax + 1]
  mov rdi, target
  rep movsb

  mov rdi, target
  call waysToMake
  add accumulator, rax

  cmp currChar, endOfFile
  jb .countLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; template as memoized inlined-looped-mutual-ref depth-first search
;; rdi = design to make, as pointer into target
;; returns how many ways this design can be made
waysToMake:
  ; memoization - if we've been asked about this position before, just return that
  mov rdx, rdi
  sub rdx, target
  mov rax, [memoize + 8 * rdx]
  cmp rax, -1
  jne .memoized

  ; base case - if design to make is empty, yes, we can trivially make it one way
  cmp BYTE [rdi], 0
  je .one

  ; inlined looped recursive case - search through possible next towels
  sub rsp, 3 * 8
  mov [rsp + 0 * 8], rdi ; save design to make
  mov QWORD [rsp + 1 * 8], towels ; save towel to try
  mov QWORD [rsp + 2 * 8], 0 ; save current count
.tryTowelLoop:
  mov rsi, [rsp + 1 * 8]
  mov rdi, [rsp + 0 * 8]
  ; base case - if no towels left to try, report how many this loop made
  cmp BYTE [rsi], 0
  je .endTryTowelLoop

  ; recursive case - try this towel

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
  call waysToMake
  add [rsp + 2 * 8], rax

.continueTryTowelLoop:
  add QWORD [rsp + 1 * 8], 16
  jmp .tryTowelLoop
.endTryTowelLoop:
  mov rdi, [rsp + 0 * 8]
  mov rsi, [rsp + 1 * 8]
  mov rax, [rsp + 2 * 8]
  add rsp, 3 * 8

  mov rdx, rdi
  sub rdx, target
  mov [memoize + 8 * rdx], rax
  
  ret

.one:
  mov rax, 1
  
  mov rdx, rdi
  sub rdx, target
  mov [memoize + 8 * rdx], rax
  
  ret
.memoized:
  ret

section .bss
;; char towels[16][256]
;; null terminated char strings
towels: resb 16 * 512
target: resb 128
memoize: resq 128