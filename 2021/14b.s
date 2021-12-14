section .text

extern writeNewline, writeLong

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, O_RDONLY
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statBuf
  syscall
  mov rsi, [statBuf + sizeOffset] ; rsi = length of file
  mov r12, rdi ; r12 = fd

  mov rax, 9 ; mmap the file
  mov rdi, 0
  ; mov rsi, rsi ; already have size of file
  mov rdx, PROT_READ
  mov r10, MAP_PRIVATE
  mov r8, r12
  mov r9, 0
  syscall
  mov r15, rax ; r15 = current position in file

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  ; count the 20 elements in the template
  mov r12, 0
.readTemplate:

  mov dil, [r15 + r12] ; get the element
  sub dil, 'A'
  movzx rdi, dil
  inc QWORD [counts + (rdi * 8)] ; count it

  inc r12

  cmp r12, 20
  jl .readTemplate

  ; get the digraphs for the 19 digraphs in the template
  mov r12, 0
.readDigraphs:

  mov dil, [r15 + r12] ; get the first element
  sub dil, 'A'
  movzx rdi, dil
  mov sil, [r15 + r12 + 1] ; get the second element
  sub sil, 'A'
  movzx rsi, sil
  shl rdi, 8
  shl rsi, 3
  inc QWORD [digraphs1 + rdi + rsi] ; count it

  inc r12

  cmp r12, 19
  jl .readDigraphs

  add r15, 22 ; move to replacements

  ; for the 100 replacements
  mov r12, 0
.readReplacements:

  mov dil, [r15] ; get the first element
  sub dil, 'A'
  movzx rdi, dil
  shl rdi, 3
  mov sil, [r15 + 1] ; get the second element
  sub sil, 'A'
  movzx rsi, sil
  shl rsi, 3

  add r15, 6 ; skip to the inserted element

  mov dl, [r15] ; get the inserted element
  sub dl, 'A'
  movzx rdx, dl
  shl rdx, 3

  lea rax, [counts + rdx]
  mov [replacements + r12 + 24], rax ; store the count address

  shl rdi, 5
  lea rax, [rdi + rsi]
  mov [replacements + r12 + 0], rax ; store the input digraph offset

  lea rax, [rdi + rdx]
  mov [replacements + r12 + 8], rax ; store the first output digraph offset

  shl rdx, 5
  lea rax, [rdx + rsi]
  mov [replacements + r12 + 16], rax ; store the second output digraph offset

  add r15, 2 ; next line
  add r12, 4*8

  cmp r12, 100*4*8
  jl .readReplacements

  mov rsi, digraphs1
  mov rdi, digraphs2

  ; apply the replacements 40 times
  mov r8, 0
.applyReplacements:

  ; clear the output buffer
  mov rbx, rdi
  mov rcx, 32*26
  mov rax, 0
  rep stosq
  mov rdi, rbx

  ; for each of the 100 replacements
  mov r9, 0
.applyReplacement:

  mov rax, [replacements + r9 + 0] ; get the input digraph offset
  mov rax, [rsi + rax] ; get the input digraph count

  mov rbx, [replacements + r9 + 24] ; get the count address
  add [rbx], rax ; add the count to the count address
  
  mov rbx, [replacements + r9 + 8] ; get the first output digraph offset
  add [rdi + rbx], rax ; add the count to the first output digraph

  mov rbx, [replacements + r9 + 16] ; get the second output digraph offset
  add [rdi + rbx], rax ; add the count to the second output digraph

  add r9, 4*8

  cmp r9, 100*4*8
  jl .applyReplacement

  mov rax, rsi ; swap buffers
  mov rsi, rdi
  mov rdi, rax

  inc r8

  cmp r8, 40
  jl .applyReplacements

  ; count elements
  mov r8, 0 ; r8 = most common element count
  mov r9, -1 ; r9 = least common element count
  ; for the 26 elements
  mov r12, 0
.countElement:

  mov rdi, [counts + (r12 * 8)]
  test rdi, rdi
  jz .skipZero

  cmp rdi, r8
  cmova r8, rdi

  cmp rdi, r9
  cmovb r9, rdi

.skipZero:

  inc r12

  cmp r12, 26
  jl .countElement

  mov rdi, r8
  sub rdi, r9
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
;; to get the digraph count
;; multiply first element by 256 (shl 8), add second element times eight (shl 3)
digraphs1:
  resq 32*26
digraphs2:
  resq 32*26
counts:
  resq 26
;; struct replacement {
;;   unsigned long *digraphIn
;;   unsigned long *digraphOneOut
;;   unsigned long *digraphTwoOout
;;   unsigned long *countIncreased
;; }
replacements:
  resq 4*100