%use fp

extern mmap, putlong, newline, exit, countc, alloc, findc, atol, abort, qsortby_T, qsort

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define boxes r13
%define circuits r14
%define length r15
%define distances r12
%define numDistances rbx

;; struct Box {
;;     #[unaligned]
;;     position: ymm
;;     circuit: *i64
;; }
%define sizeOfBox (64)
%define boxPositionOffset (0 * 32)
%define boxCircuitOffset (1 * 32)

;; struct Distance {
;;     distance: f64
;;     box1: *Box
;;     box2: *Box
;; }
%define sizeOfDistance (32)
%define distanceDistanceOffset (0 * 8)
%define distanceBox1Offset (1 * 8)
%define distanceBox2Offset (2 * 8)

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

  ; count number of boxes
  mov rdi, currChar
  mov rsi, endOfFile
  mov dl, `\n`
  call countc
  mov length, rax

  ; allocate array of boxes
  mov rdi, length
  shl rdi, 6
  call alloc
  mov boxes, rax

  ; allocate array of circuits
  mov rdi, length
  shl rdi, 3
  call alloc
  mov circuits, rax

  ; initialize circuits
  mov rax, 1
  mov rcx, length
  mov rdi, circuits
  rep stosq

  ; parse input into array of boxes
  mov rbx, boxes ; rbx = current box
  mov rbp, circuits ; rbp = current circuit
.readLoop:

  ; parse first number
  mov rdi, currChar
  mov sil, ','
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  cvtsi2sd xmm0, rax
  movsd [rbx + boxPositionOffset + 0 * 8], xmm0

  inc currChar

  ; parse second number
  mov rdi, currChar
  mov sil, ','
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  cvtsi2sd xmm0, rax
  movsd [rbx + boxPositionOffset + 1 * 8], xmm0

  inc currChar

  ; parse third number
  mov rdi, currChar
  mov sil, `\n`
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  cvtsi2sd xmm0, rax
  movsd [rbx + boxPositionOffset + 2 * 8], xmm0

  inc currChar

  ; initialize circuit
  mov [rbx + boxCircuitOffset], rbp

  ; move to next
  add rbx, sizeOfBox
  add rbp, 8

  cmp currChar, endOfFile
  jb .readLoop

  ; allocate space for pairwise distances
  mov rax, length
  lea rdi, [length - 1]
  mul rdi
  shr rax, 1
  mov numDistances, rax
  mov rdi, numDistances
  shl rdi, 5
  call alloc
  mov distances, rax

  ; calculate pairwise distances - i.e. the distance between box pointer a and box pointer b is d
  mov rdi, 0
  mov rdx, distances ; rdx = current distance
  mov rbx, 0
.calculateDistanceLoop:

  ; r8 = pointer to box a
  mov r8, rdi
  shl r8, 6
  add r8, boxes

  mov rsi, rdi
  inc rsi
.calculateDistanceInnerLoop:

  ; r9 = pointer to box b
  mov r9, rsi
  shl r9, 6
  add r9, boxes

  ; calculate distance
  vmovupd ymm0, [r8 + boxPositionOffset]
  vmovupd ymm1, [r9 + boxPositionOffset]
  vsubpd ymm0, ymm0, ymm1
  vmulpd ymm0, ymm0, ymm0
  vhaddpd ymm0, ymm0, ymm0
  vextractf128 xmm1, ymm0, 1
  addsd xmm0, xmm1

  movsd [rdx + distanceDistanceOffset], xmm0
  mov [rdx + distanceBox1Offset], r8
  mov [rdx + distanceBox2Offset], r9

  inc rsi
  add rdx, sizeOfDistance
  inc rbx

  cmp rsi, length
  jb .calculateDistanceInnerLoop

  inc rdi
  
  mov rax, rdi
  inc rax
  cmp rax, length
  jb .calculateDistanceLoop

  ; sort pairwise distances
  mov rdi, distances
  mov rsi, numDistances
  shl rsi, 5
  add rsi, distances
  mov rdx, compareDistances
  mov rcx, sizeOfDistance
  call qsortby_T

  ; for each pair
.joinLoop:
  ; get pointers to boxes
  mov r8, [distances + distanceBox1Offset]
  mov r9, [distances + distanceBox2Offset]

  ; try linking these if not already linked
  mov rdi, [r8 + boxCircuitOffset]
  mov rsi, [r9 + boxCircuitOffset]
  cmp rdi, rsi
  je .continueJoinLoop

  ; add the count of boxes on circuit 2 to circuit 1
  mov rax, [rsi]
  add [rdi], rax
  
  ; if this linked together everyone, break
  cmp [rdi], length
  je .endJoinLoop

  ; for every box, if it was on circuit 2, assign it to circuit 1
  mov r8, 0
.setCircuitLoop:

  mov r9, r8
  shl r9, 6
  add r9, boxes

  cmp rsi, [r9 + boxCircuitOffset]
  jne .continueSetCircuitLoop

  mov [r9 + boxCircuitOffset], rdi

.continueSetCircuitLoop:
  inc r8

  cmp r8, length
  jb .setCircuitLoop

.continueJoinLoop:
  add distances, sizeOfDistance
  jmp .joinLoop
.endJoinLoop:

  ; rdi = last box 1
  cvtsd2si rax, [r8 + boxPositionOffset + 0 * 8]
  ; rsi = last box 2
  cvtsd2si rdi, [r9 + boxPositionOffset + 0 * 8]
  imul rdi

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi: *Distance
;; rsi: *Distance
;; returns:
;; a negative number if rdi < rsi
;; 0 if rdi == rsi
;; a positive number if rdi > rsi
;; based on the distance
compareDistances:
  movsd xmm0, [rdi + 0]
  movsd xmm1, [rsi + 0]
  ucomisd xmm0, xmm1
  jp abort
  jb .less
  ja .greater

.equal:
  mov rax, 0
  ret
.less:
  mov rax, -1
  ret
.greater:
  mov rax, 1
  ret
