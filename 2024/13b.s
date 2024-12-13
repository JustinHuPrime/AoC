extern exit, mmap, putlong, newline, findnotnum, atol, abort

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define accumulator QWORD [rsp + 8]

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0, endOfFile
  ;; rsp + 8, accumulator

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov accumulator, 0

.loop:

  add currChar, 12 ; skip "Button A: X+"
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov [matrix + 0 * 8], rax

  add currChar, 4 ; skip ", Y+"
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov [matrix + 2 * 8], rax

  add currChar, 13 ; skip "\nButton B: X+"
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov [matrix + 1 * 8], rax

  add currChar, 4 ; skip ", Y+"
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov [matrix + 3 * 8], rax

  add currChar, 10 ; skip "\nPrize: X="
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov rdx, 10000000000000
  add rax, rdx
  mov [prize + 0 * 8], rax

  add currChar, 4 ; skip ", Y="
  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol ; parse number
  mov rdx, 10000000000000
  add rax, rdx
  mov [prize + 1 * 8], rax

  add currChar, 2 ; skip newlines

  ; calculate determinant
  mov rdi, [matrix + 0 * 8]
  imul rdi, [matrix + 3 * 8]
  mov rax, [matrix + 1 * 8]
  imul rax, [matrix + 2 * 8]
  sub rdi, rax
  mov [determinant], rdi

  test rdi, rdi
  jz .colinear

  ; not colinear - do change of basis

  ; compute inverse matrix
  mov rax, [matrix + 0 * 8]
  mov [inverse + 3 * 8], rax
  mov rax, [matrix + 1 * 8]
  neg rax
  mov [inverse + 1 * 8], rax
  mov rax, [matrix + 2 * 8]
  neg rax
  mov [inverse + 2 * 8], rax
  mov rax, [matrix + 3 * 8]
  mov [inverse + 0 * 8], rax

  ; apply inverse matrix for A presses
  mov rdi, [inverse + 0 * 8]
  imul rdi, [prize + 0 * 8]
  mov rax, [inverse + 1 * 8]
  imul rax, [prize + 1 * 8]
  add rax, rdi
  cqo
  idiv QWORD [determinant]

  test rdx, rdx
  jnz .continueLoop ; doesn't divide: decimal number of presses needed
  test rax, rax
  js .continueLoop ; negative number of presses needed
  mov [presses + 0 * 8], rax

  ; apply inverse matrix for B presses
  mov rdi, [inverse + 2 * 8]
  imul rdi, [prize + 0 * 8]
  mov rax, [inverse + 3 * 8]
  imul rax, [prize + 1 * 8]
  add rax, rdi
  cqo
  idiv qword [determinant]

  test rdx, rdx
  jnz .continueLoop ; doesn't divide: decimal number of presses needed
  test rax, rax
  js .continueLoop ; negative number of presses needed
  mov [presses + 1 * 8], rax

  imul rax, [presses + 0 * 8], 3
  add accumulator, rax
  mov rax, [presses + 1 * 8]
  add accumulator, rax

  jmp .continueLoop
.colinear:

  ; ; is the prize also colinear?
  ; mov rax, [matrix + 0 * 8]
  ; imul rax, [prize + 1 * 8]
  ; mov rdx, [matrix + 1 * 8]
  ; imul rdx, [prize + 0 * 8]
  ; cmp rax, rdx
  ; jne .continueLoop ; not colinear, bail!

  ud2

.continueLoop:

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
matrix: resq 2 * 2
inverse: resq 2 * 2
prize: resq 2
presses: resq 2
determinant: resq 1