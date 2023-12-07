extern exit, mmap, putlong, newline, findnl, atol

section .text

%define curr r12
%define eof [rsp + 0]
%define arryPtr r13
%define accumulator r12
%define arryIdx r13

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

  ; do-while curr < eof
  mov arryPtr, hands
.readLoop:

  call readHandChar
  call readHandChar
  call readHandChar
  call readHandChar
  call readHandChar

  inc curr ; skip ' '
  inc arryPtr ; skip padding

  ; parse number
  mov rdi, curr
  call findnl
  mov rdi, curr
  mov rsi, rax
  mov curr, rax
  call atol

  mov [arryPtr], ax

  add arryPtr, 2
  inc curr ; skip '\n'

  cmp curr, eof
  jb .readLoop

  ; sort cards
  mov rdi, hands
  mov rsi, hands
; do-while *rsi != 0
.findEndOfHandsLoop:

  add rsi, 8

  cmp QWORD [rsi], 0
  jne .findEndOfHandsLoop
  call qsortHands

  ; sum bids
  mov accumulator, 0
  mov arryIdx, 0
; do-while hands[arryIdx] != 0
.sumBidsLoop:

  mov ax, [hands + arryIdx * 8 + 6]
  movzx rax, ax

  inc arryIdx

  imul rax, arryIdx
  add accumulator, rax

  cmp QWORD [hands + arryIdx * 8], 0
  jne .sumBidsLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; subroutine
;; uses curr
;; uses arryPtr
;; clobbers rax
readHandChar:

  cmp BYTE [curr], 'A'
  jne .notAce

  mov BYTE [arryPtr], 14

  jmp .end
.notAce:

  cmp BYTE [curr], 'K'
  jne .notKing

  mov BYTE [arryPtr], 13

  jmp .end
.notKing:

  cmp BYTE [curr], 'Q'
  jne .notQueen

  mov BYTE [arryPtr], 12

  jmp .end
.notQueen:

  cmp BYTE [curr], 'J'
  jne .notJack

  mov BYTE [arryPtr], 11

  jmp .end
.notJack:

  cmp BYTE [curr], 'T'
  jne .notTen

  mov BYTE [arryPtr], 10

  jmp .end
.notTen:

  mov al, [curr]
  sub al, '0'
  mov [arryPtr], al

.end:

  inc curr
  inc arryPtr
  ret

%define end [rsp + 0]
%define start [rsp + 8]
%define pivot [rsp + 16]

;; rdi = start of range to sort
;; rsi = end of range to sort
;; effect: sorts range according to cards hand strength
;; returns void
qsortHands:
  ; if range is one item, return
  cmp rdi, rsi
  je .end

  sub rsp, 3 * 8
  ;; stack slots:
  ;; rsp + 0 = end of range
  ;; rsp + 8 = start of range
  ;; rsp + 16 = pivot position

  mov end, rsi
  mov start, rdi

  ; for each element in the range (at least one)
  ; invariant: rdi = pivot address
  ; invariant: rdx = pivot value
  ; invariant: array looks like:
  ; x, x ... x, x, x ...
  ; ^  ^     ^
  ; |  |     + rsi = current element
  ; |  + rdi + 8 = greater than pivot
  ; + rdi = spot for pivot; value undefined
  mov rdx, [rdi]
  mov rsi, rdi ; rsi = current element
  ; do while rsi < end
.loop:

  push rdi
  push rdx
  push rsi

  mov rdi, [rsi]
  mov rsi, rdx
  call compareHands
  cmp rax, 0

  pop rsi
  pop rdx
  pop rdi

  jge .continue ; not less than pivot and after pivot; do nothing

  mov rax, [rsi] ; insert rsi at current pivot position
  mov [rdi], rax
  
  mov rax, [rdi + 8] ; move greater than pivot to current position
  mov [rsi], rax

  add rdi, 8 ; move pivot position

.continue:
  add rsi, 8

  cmp rsi, end
  jl .loop

  mov [rdi], rdx ; re-insert pivot
  mov pivot, rdi ; save pivot position

  mov rdi, start ; rdi = start of range
  mov rsi, pivot ; rsi = pivot position
  call qsortHands

  mov rdi, pivot ; rdi = one more than pivot position
  add rdi, 8
  mov rsi, end ; rsi = end of range
  call qsortHands

  add rsp, 3 * 8

.end:
  ret

;; rdi = first hand
;; rsi = second hand
;; returns rdi "minus" rsi
compareHands:
  push rdi
  push rsi
  call compareRank
  pop rsi
  pop rdi
  cmp rax, 0
  jne .end

  ; compare based on values
  bswap rdi
  shr rdi, 24
  bswap rsi
  shr rsi, 24
  sub rdi, rsi
  mov rax, rdi

.end:
  ret

;; rdi = first hand
;; rsi = second hand
;; returns rdi "minus" rsi, based on rank only
compareRank:
  push rsi
  call getHandRank
  pop rdi

  push rax
  call getHandRank
  mov rdi, rax
  pop rax

  sub rax, rdi
  ret

;; rdi = hand
;; calculate numeric value for hand rank
;; returns a numeric value describing the hand's rank
;;   count the cards from 2 to 14, add one to every count
;;   sum the squares of the counts
getHandRank:
  mov [handBuffer], rdi

  mov rdi, counts + 2 * 8
  mov rcx, 13
  mov rax, 1
  rep stosq

  mov al, [handBuffer + 0]
  ; movzx rax, al ; rax is already clear enough
  inc QWORD [counts + rax * 8]
  mov al, [handBuffer + 1]
  inc QWORD [counts + rax * 8]
  mov al, [handBuffer + 2]
  inc QWORD [counts + rax * 8]
  mov al, [handBuffer + 3]
  inc QWORD [counts + rax * 8]
  mov al, [handBuffer + 4]
  inc QWORD [counts + rax * 8]

  mov rdi, 0
  mov rsi, counts + 2 * 8
  mov rcx, 13
.productLoop:

  lodsq
  imul rax, rax
  add rdi, rax

  loop .productLoop

  mov rax, rdi
  ret

section .bss
;; struct hand {
;;   byte[5] cards;
;;   byte[1] padding;
;;   word bid;
;; }
hands: resq 1001
handBuffer: resq 1
counts: resq 15