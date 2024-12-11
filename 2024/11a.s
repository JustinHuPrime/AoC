extern exit, mmap, putlong, newline, alloc, findws, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define listHead r13
%define listTail r14
%define accumulator r12
%define curr r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax

  ; store as circular doubly-linked list with dummy node
  ;; struct ListNode {
  ;;   ListNode *prev;
  ;;   ListNode *next;
  ;;   unsigned qword datum;
  ;; }
  %define sizeofNode 3 * 8
  %define prevNode 0
  %define nextNode 8
  %define dataNode 16
  mov rdi, sizeofNode
  call alloc
  mov listHead, rax
  mov listTail, rax
  mov [listHead + prevNode], listTail
  mov [listTail + nextNode], listHead
  mov QWORD [listHead + dataNode], -1

  ; read initial list
.readLoop:

  mov rdi, currChar
  call findws
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol

  mov r15, rax

  mov rdi, sizeofNode
  call alloc
  mov [rax + dataNode], r15
  mov rdx, [listTail + prevNode]
  mov [rax + prevNode], rdx
  mov [rax + nextNode], listTail
  mov [rdx + nextNode], rax
  mov [listTail + prevNode], rax

  inc currChar

  cmp BYTE [currChar - 1], `\n`
  jne .readLoop

  ; loop
  mov rbx, 25
.computeLoop:

  ; move through the list
  mov curr, listHead
.computeElementLoop:
  mov curr, [curr + nextNode]
  cmp curr, listTail
  je .endComputeElementLoop

  ; check - is this element zero
  cmp QWORD [curr + dataNode], 0
  jne .notZero

  mov QWORD [curr + dataNode], 1

  jmp .continueComputeElementLoop
.notZero:
  
  ; check - is this element splittable
  mov rdi, [curr + dataNode]
  call split
  cmp rax, 0
  je .notSplit

  mov rdi, rax
  mov rax, [curr + dataNode]
  mov rdx, 0
  div rdi
  mov [curr + dataNode], rdx ; rdx = second half
  mov rbp, rax ; rbp = first half

  ; create new node for first half
  mov rdi, sizeofNode
  call alloc
  mov rdx, [curr + prevNode]
  mov [rax + prevNode], rdx
  mov [rax + nextNode], curr
  mov [rdx + nextNode], rax
  mov [curr + prevNode], rax
  mov [rax + dataNode], rbp

  jmp .continueComputeElementLoop
.notSplit:

  ; multiply by 2024
  mov rax, [curr + dataNode]
  mov rdi, 2024
  mul rdi
  mov [curr + dataNode], rax

.continueComputeElementLoop:

  jmp .computeElementLoop
.endComputeElementLoop:

  dec rbx

  cmp rbx, 0
  jne .computeLoop

  ; count stones
  mov accumulator, 0
  mov rax, listHead
.countLoop:
  mov rax, [rax + nextNode]
  inc accumulator
  cmp rax, listTail
  jne .countLoop

  dec accumulator ; remove the dummy node

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; Computes if the number has an even number of digits and, if so, what the
;; split number is going to be
split:
  cmp rdi, 10
  jb .noSplit

  cmp rdi, 100
  jnb .gt100

  ; 10 <= rdi < 100
  ; split with 10
  mov rax, 10
  ret

.gt100:
  cmp rdi, 1000
  jb .noSplit

  cmp rdi, 10000
  jnb .gt10000

  ; 1000 <= rdi < 10000
  ; split with 100
  mov rax, 100
  ret

.gt10000:
  cmp rdi, 100000
  jb .noSplit

  cmp rdi, 1000000
  jnb .gt1000000

  ; 100000 <= rdi < 1000000
  ; split with 1000
  mov rax, 1000
  ret

.gt1000000:
  cmp rdi, 10000000
  jb .noSplit

  cmp rdi, 100000000
  jnb .gt100000000

  ; 10000000 <= rdi < 100000000
  ; split with 10000
  mov rax, 10000
  ret

.gt100000000:
  mov rax, 1000000000
  cmp rdi, rax
  jb .noSplit

  mov rax, 10000000000
  cmp rdi, rax
  jnb .gt10000000000

  ; 1000000000 <= rdi < 10000000000
  ; split with 100000
  mov rax, 100000
  ret

.gt10000000000:
  mov rax, 100000000000
  cmp rdi, rax
  jb .noSplit

  mov rax, 1000000000000
  cmp rdi, rax
  jnb .gt1000000000000

  ; 100000000000 <= rdi < 1000000000000
  ; split with 1000000
  mov rax, 1000000
  ret

.gt1000000000000:
  mov rax, 10000000000000
  cmp rdi, rax
  jb .noSplit

  mov rax, 100000000000000
  cmp rdi, rax
  jnb .gt100000000000000

  ; 10000000000000 <= rdi < 100000000000000
  ; split with 10000000
  mov rax, 10000000
  ret

.gt100000000000000:
  mov rax, 1000000000000000
  cmp rdi, rax
  jb .noSplit

  mov rax, 10000000000000000
  cmp rdi, rax
  jnb .gt10000000000000000

  ; 1000000000000000 <= rdi < 10000000000000000
  ; split with 100000000
  mov rax, 100000000
  ret

.gt10000000000000000:
  mov rax, 100000000000000000
  cmp rdi, rax
  jb .noSplit

  mov rax, 1000000000000000000
  cmp rdi, rax
  jnb .gt1000000000000000000

  ; 100000000000000000 <= rdi < 1000000000000000000
  ; split with 1000000000
  mov rax, 1000000000
  ret

.gt1000000000000000000:
  mov rax, 10000000000000000000
  cmp rdi, rax
  jb .noSplit
  
  ; can't be too large for this split
  mov rax, 1000000000
  ret

.noSplit:
  mov rax, 0
  ret
