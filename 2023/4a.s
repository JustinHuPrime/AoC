extern exit, mmap, putlong, newline, atol, skipws, findws

section .text

%define accumulator [rsp + 0]
%define curr r12
%define endOfFile [rsp + 8]
%define endOfWinning r13
%define numMatching r14
%define numMatchingb r14b

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0 = accumulator
  ;; rsp + 8 = endOfFile

  mov curr, rax
  add rax, rdx
  mov endOfFile, rax

  mov QWORD accumulator, 0

  ; do-while curr < eof
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

  ; add to accumulator
  test numMatching, numMatching
  jz .noneToAdd

  dec numMatching
  mov cl, numMatchingb
  mov rax, 1
  shl rax, cl
  add accumulator, rax

.noneToAdd:

  ; skip EOL
  inc curr

  cmp curr, endOfFile
  jb .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

winning: resb 10