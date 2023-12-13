extern exit, mmap, putlong, newline, streq, puts

section .text

%define curr rbx
%define eof r13
%define SIZE 32
%define x rbp
%define y r12
%define accumulator r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ;; sub rsp, 0 * 8
  ;; slots
  ;; rsp + 0 = 

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; for each pattern
  mov QWORD accumulator, 0
.patternsLoop:
  ; clear maps
  mov rdi, map
  mov al, 0
  mov rcx, SIZE * SIZE
  rep stosb

  mov rdi, transposed
  mov al, 0
  mov rcx, SIZE * SIZE
  rep stosb

  ; read in pattern, including transpose
  mov y, 0
.readPatternLoop:
  mov x, 0

.readPatternLineLoop:
  mov al, [curr]
  mov rdi, x
  mov rsi, y
  shl rdi, 5
  shl rsi, 5
  mov [map + x + rsi], al
  mov [transposed + y + rdi], al

  inc x
  inc curr

  cmp BYTE [curr], `\n`
  jne .readPatternLineLoop

  inc curr ; skip newline
  inc y

  cmp BYTE [curr], `\n`
  je .endReadPatternLoop
  cmp curr, eof
  jb .readPatternLoop
.endReadPatternLoop:

  inc curr ; skip next newline

  ; find reflections

  mov rdi, transposed
  call findReflection
  test rax, rax
  jnz .skipFindOtherReflection

  mov rdi, map
  call findReflection
  mov rdi, 100
  imul rax, rdi

.skipFindOtherReflection:

  add accumulator, rax

  cmp curr, eof
  jb .patternsLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

%define currRow rsi
%define reflectionRow rdx
%define index rax
%define arry rdi

;; rdi = map array
;; returns number of rows to reflection, or 0
;; clobbers
findReflection:
  mov index, 1
  lea currRow, [arry + SIZE]
  mov reflectionRow, arry

  ; for each line
.findCandidateLoop:
  push arry
  push reflectionRow
  push index
  push currRow
  mov rdi, currRow
  mov rsi, reflectionRow
  call streq
  test al, al
  pop currRow
  pop index
  pop reflectionRow
  pop arry
  jz .continueFindCandidateLoop

  ; is a candidate - check for further equality
  push currRow
  push reflectionRow
.confirmCandidateLoop:
  ; move to next pair of rows
  add currRow, SIZE
  sub reflectionRow, SIZE
  
  ; if either are out of bounds, validate candidate
  cmp BYTE [currRow], 0
  je .isReflection
  cmp reflectionRow, arry
  jb .isReflection

  push arry
  push reflectionRow
  push index
  push currRow
  mov rdi, currRow
  mov rsi, reflectionRow
  call streq
  test al, al
  pop currRow
  pop index
  pop reflectionRow
  pop arry
  jnz .confirmCandidateLoop

  ; candidate check failed - continue
  pop reflectionRow
  pop currRow

.continueFindCandidateLoop:
  inc index
  add currRow, SIZE
  add reflectionRow, SIZE

  cmp BYTE [currRow], 0
  jne .findCandidateLoop

  mov rax, 0
  ret

.isReflection:
  add rsp, 2 * 8
  ret

section .bss
map: resb SIZE * SIZE
transposed: resb SIZE * SIZE
