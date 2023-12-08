extern exit, mmap, putlong, newline, lcm

section .text

%define curr r12
%define eof [rsp + 0]
%define arryPtr r13
%define startingNodeArryPtr r15
%define twentysix rbp
%define currPlace r12
%define currStep r13
%define stepCount r14
%define accumulator r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; parse input

  ; clear arrays  
  mov rax, 0
  not rax

  ; clear instructions with 0xff
  mov rdi, instructions
  mov rcx, 1024
  rep stosb

  ; clear map with 0xffff, 0xffff
  mov rdi, map
  mov rcx, 17576
  rep stosd

  ; clear starting nodes with 0xffffffffffffffff
  mov rdi, startingNodes
  mov rcx, 1024
  rep stosq

  mov arryPtr, instructions
  ; do-while *curr != '\n'
.readInstructionsLoop:
  mov al, 0
  mov dil, 2
  cmp BYTE [curr], 'R'
  cmove ax, di
  mov [arryPtr], al

  inc curr
  inc arryPtr

  cmp BYTE [curr], 0xa
  jne .readInstructionsLoop

  ; skip '\n\n'
  add curr, 2

  ; do-while curr < EOF
  mov twentysix, 26
  mov startingNodeArryPtr, startingNodes
.readMapLoop:

  ; rax = index
  mov al, BYTE [curr + 0]
  movzx rax, al
  sub rax, 'A'
  imul rax, twentysix
  imul rax, twentysix

  mov dil, BYTE [curr + 1]
  movzx rdi, dil
  sub rdi, 'A'
  imul rdi, twentysix
  add rax, rdi

  mov dil, BYTE [curr + 2]
  movzx rdi, dil
  sub rdi, 'A'
  add rax, rdi

  ; if rdi == 0, then this is a starting node (ends with A)
  test rdi, rdi
  jnz .notStartingNode

  mov [startingNodeArryPtr], rax
  add startingNodeArryPtr, 8

.notStartingNode:

  ; skip "??? = ("
  add curr, 7

  ; rdi = left
  mov dil, BYTE [curr + 0]
  movzx rdi, dil
  sub rdi, 'A'
  imul rdi, twentysix
  imul rdi, twentysix

  mov sil, BYTE [curr + 1]
  movzx rsi, sil
  sub rsi, 'A'
  imul rsi, twentysix
  add rdi, rsi

  mov sil, BYTE [curr + 2]
  movzx rsi, sil
  sub rsi, 'A'
  add rdi, rsi

  ; skip "???, "
  add curr, 5

  ; rsi = right
  mov sil, BYTE [curr + 0]
  movzx rsi, sil
  sub rsi, 'A'
  imul rsi, twentysix
  imul rsi, twentysix

  mov dl, BYTE [curr + 1]
  movzx rdx, dl
  sub rdx, 'A'
  imul rdx, twentysix
  add rsi, rdx

  mov dl, BYTE [curr + 2]
  movzx rdx, dl
  sub rdx, 'A'
  add rsi, rdx

  ; skip "???)\n"
  add curr, 5

  ; store map pointers
  mov [map + rax * 4], di
  mov [map + rax * 4 + 2], si

  cmp curr, eof
  jb .readMapLoop

  ; do-while *startingNodeArryPtr != 0xffffffffffffffff
  mov startingNodeArryPtr, startingNodes
.eachStartingPointLoop:

  ; traverse it
  mov rax, [startingNodeArryPtr]
  lea currPlace, [map + rax * 4]
  mov currStep, instructions
  mov stepCount, 0
  ; do-while ((currPlace - map) / 4) % 26 != 25

.traverseLoop:

  ; get current step - either 0 or 2
  mov al, [currStep]
  movzx rax, al

  ; get address containing index of next place
  mov ax, [currPlace + rax]
  movzx rax, ax

  ; store address of next place
  lea currPlace, [map + rax * 4]

  ; next step, wrapping around if we hit the end
  inc currStep
  mov rax, instructions
  cmp BYTE [currStep], 0xff
  cmove currStep, rax

  ; this was one step
  inc stepCount

  mov rax, currPlace
  sub rax, map
  shr rax, 2
  cqo
  div twentysix
  
  cmp rdx, 25
  jne .traverseLoop

  ; store step count
  mov [startingNodeArryPtr], stepCount

  add startingNodeArryPtr, 8

  cmp QWORD [startingNodeArryPtr], 0xffffffffffffffff
  jne .eachStartingPointLoop

  ; calculate LCM of step counts
  mov accumulator, [startingNodes]
  mov startingNodeArryPtr, startingNodes
  ; do-while *startingNodes != 0xffffffffffffffff
.lcmLoop:
  mov rdi, accumulator
  mov rsi, [startingNodeArryPtr]
  call lcm
  mov accumulator, rax

  add startingNodeArryPtr, 8

  cmp QWORD [startingNodeArryPtr], 0xffffffffffffffff
  jne .lcmLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
instructions: resb 1024
;; struct node {
;;   ; word id; // id = offset into structure, where AAA = 0, AAZ = 25, ABA = 26, AZA = 650, and so on
;;   word left;
;;   word right;
;; }
;; sizeof(node) == 4 == sizeof(dword)
map: resd 17576
startingNodes: resq 1024