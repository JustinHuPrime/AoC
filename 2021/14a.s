section .text

extern writeNewline, writeLong, alloc

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

  ; set up dummy node
  mov rdi, 16
  call alloc
  mov BYTE [rax + 0], 0xff
  mov QWORD [rax + 8], 0
  mov r14, rax ; r14 = polymer

  ;; struct polymernode {
  ;;   char element;
  ;;   char[7] padding;
  ;;   struct polymernode *next;
  ;; };

  ; for the 20 elements in the template
  mov r12, 20
.readTemplate:

  mov rdi, 16 ; save it to the linked list
  call alloc
  mov dil, [r15 + r12 - 1]
  mov [rax + 0], dil
  mov [rax + 8], r14
  mov r14, rax

  dec r12

  cmp r12, 0
  jg .readTemplate

  add r15, 22 ; move to replacements

  ; for the 100 replacements
  mov r12, 0
.readReplacements:

  mov di, [r15] ; save the first and second elements
  mov [replacements + (r12 * 4) + 0], di

  add r15, 6 ; skip to the inserted element

  mov dil, [r15] ; save the inserted element
  mov [replacements + (r12 * 4) + 2], dil

  add r15, 2 ; next line
  inc r12

  cmp r12, 100
  jl .readReplacements

  ; apply the replacements 10 times
  mov r8, 0
.applyReplacements:

  ; for each node in the linked list
  mov r13, r14
.applyReplacementNode:

  mov al, [r13 + 0] ; get current elemnt
  mov rdi, [r13 + 8]
  mov ah, [rdi + 0] ; get next element

  ; for each of the 100 replacements
  mov r9, 0
.findReplacement:

  mov di, [replacements + (r9 * 4) + 0] ; get elements
  cmp ax, di
  jne .continue

  ; match found - insert it
  mov rdi, 16
  call alloc
  mov dil, [replacements + (r9 * 4) + 2]
  mov [rax + 0], dil ; newNode->element = replacement
  mov rdi, [r13 + 8] ; rdi = currentNode->next
  mov [rax + 8], rdi ; newNode->next = currentNode->next
  mov [r13 + 8], rax ; currentNode->next = newNode
  mov r13, rax ; currentNode = newNode
  jmp .replaced

.continue:

  inc r9

  cmp r9, 100
  jl .findReplacement
.replaced:

  mov r13, [r13 + 8] ; next node

  cmp QWORD [r13 + 8], 0
  jne .applyReplacementNode

  inc r8

  cmp r8, 10
  jl .applyReplacements

  ; count elements
.countElements:

  mov dil, [r14 + 0]
  movzx rdi, dil
  inc QWORD [counts + ((rdi - 'A') * 8)]

  mov r14, [r14 + 8]

  cmp QWORD [r14 + 8], 0
  jne .countElements

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
counts:
  resq 26
;; struct replacement {
;;   char element1;
;;   char element2;
;;   char inserted;
;;   char[1] padding;
;; }
replacements:
  resb 4*100