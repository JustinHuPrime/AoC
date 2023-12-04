extern exit, mmap, putlong, newline, atol, skipws, findws

section .text

%define curr r12
%define endOfFile [rsp + 0]
%define endOfWinning r13
%define numMatching r14
%define numMatchingb r14b
%define cardNum r15
%define accumulator [rsp + 8]

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0 = endOfFile
  ;; rsp + 8 = accumulator

  mov curr, rax
  add rax, rdx
  mov endOfFile, rax

  ; for each card, calculate how many other cards it wins
  ; do-while curr < eof
  mov cardNum, 0
.lineLoop:

  ; reset
  mov endOfWinning, winning
  mov numMatching, 0

  ; skip "Card"
  add curr, 4

  ; skip leading whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  ; skip "###:"
  mov rdi, curr
  call findws
  mov curr, rax

  ; read winning numbers
.readWinningLoop:
  ; skip leading whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  ; consider character - end of it is a bar
  cmp BYTE [curr], '|'
  je .endReadWinningLoop

  ; parse current number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol
  mov [endOfWinning], al
  inc endOfWinning
  
  jmp .readWinningLoop
.endReadWinningLoop:

  inc curr ; skip "|"

  ; read number we have
.readHaveLoop:

  ; skip leading whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  ; parse current number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol

  ; if this matches a number we have
  mov rdi, winning
  ; do-while rdi < endOfWinning
.checkWinningLoop:

  cmp [rdi], al
  jne .continueCheckWinningLoop

  inc numMatching
  jmp .endCheckWinningLoop

.continueCheckWinningLoop:
  inc rdi

  cmp rdi, endOfWinning
  jb .checkWinningLoop
.endCheckWinningLoop:

  ; consider character - stop if it's EOL
  cmp BYTE [curr], 0xa
  jne .readHaveLoop
  
  ; you win the next numMatching cards
  mov [cardWins + cardNum * 8], numMatching
  ; you have the one starting copy of this card
  mov QWORD [cardCounts + cardNum * 8], 1

  ; skip EOL
  inc curr

  inc cardNum

  cmp curr, endOfFile
  jb .lineLoop

  mov QWORD accumulator, 0

  ; do-while you have a copy of the current card
  mov cardNum, 0
.cardSummingLoop:

  ; the next cardWins[cardNum] cards have cardCounts[cardNum] more copies
  mov rax, [cardWins + cardNum * 8]
  add rax, cardNum ; for each card from here to cardNum

  ; do-while rax > cardNum
  mov rsi, [cardCounts + cardNum * 8]
.cardAddingLoop:
  cmp rax, cardNum
  jbe .endCardAddingLoop

  ; cardCounts[rax] += cardCounts[cardNum]
  add [cardCounts + rax * 8], rsi

  dec rax

  jmp .cardAddingLoop
.endCardAddingLoop:

  ; add the current number of cards to the accumulator
  mov rax, [cardCounts + cardNum * 8]
  add accumulator, rax

  inc cardNum

  mov rax, [cardCounts + cardNum * 8]
  test rax, rax
  jnz .cardSummingLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

winning: resb 10
cardWins: resq 214
cardCounts: resq 215 ; plus zero terminator