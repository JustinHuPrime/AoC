section .text

extern writeNewline, writeLong, atol, findComma, findNewline, findWs, skipWs

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

  ; read called numbers

  mov r11, 0 ; r11 = index of number read
  ; do ... while r11 < 99
.readNumberLoop:
  
  mov rdi, r15 ; find the comma
  call findComma
  mov rsi, rax ; read the number between here and the comma
  call atol
  mov [numbers + (r11 * 1)], al

  inc r11 ; read a number
  lea r15, [rsi + 1] ; skip the comma

  cmp r11, 99
  jl .readNumberLoop

  mov rdi, r15 ; find the newline
  call findNewline
  mov rsi, rax ; read the number between here and the newline
  call atol
  mov [numbers + (r11 * 1)], al
  lea r15, [rsi + 2] ; skip the double newline

  ; r15 now points at start of boards

  mov r11, 0 ; r11 = index of board read
  ; do ... while r11 < 100*25
.readBoardLoop:

  mov rdi, r15 ; find the witespace
  call findWs
  mov rsi, rax ; read the number between here and the whitespace
  call atol
  mov [boards + (r11 * 1)], al

  inc r11 ; read a number

  mov rdi, rsi ; skip the whitespace
  call skipWs
  mov r15, rax
  
  cmp r11, 100*25
  jl .readBoardLoop

  mov r11, 0 ; r11 = index of next number
  mov r10, 0 ; r10 = won count
  ; for each number
.callNumberLoop:

  mov r14b, [numbers + (r11 * 1)] ; r14 = number to call
  ; for each number in the board
  mov rcx, 100*25
.markNumberLoop:

  mov dil, [boards + (rcx * 1) - 1] ; if number == number to call
  cmp dil, r14b
  jne .noMark

  mov dil, 0x80 ; mark it
  mov [boards + (rcx * 1) - 1], dil

.noMark:

  loop .markNumberLoop

  ; check if a board won
  mov r12, boards
  mov r13, 0 ; r13 = index of board
.checkWin:

  mov rdi, r12
  mov rsi, r13
  call checkWin
  test rax, rax
  jz .noWin

  ; if not noted as won
  mov dil, [won + r13]
  test dil, dil
  jnz .noWin

  mov BYTE [won + r13], 0x1 ; mark it as won
  inc r10 ; increment the win count

  cmp r10, 100 ; if we have 100 wins
  je .boardWon ; this last board is the last winner

.noWin:

  add r12, 25
  inc r13

  cmp r12, boards + 100*25
  jl .checkWin

  inc r11 ; call next number

  jmp .callNumberLoop

.boardWon:
  ;; r12 = winning board
  ;; r11 = winning number

  mov rdi, r12
  call sumBoard
  movzx r14, r14b
  imul rax, r14

  mov rdi, rax
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; rdi = board to check
;; returns nonzero if won, 0 if not
;; clobbers r8, rdx
checkWin:
  mov r8, 0

  mov rsi, 0 ; column 0?
  call checkColumn
  add r8, rax

  mov rsi, 1 ; column 1?
  call checkColumn
  add r8, rax

  mov rsi, 2 ; column 2?
  call checkColumn
  add r8, rax

  mov rsi, 3 ; column 3?
  call checkColumn
  add r8, rax

  mov rsi, 4 ; column 4?
  call checkColumn
  add r8, rax

  mov rsi, 0 ; row 1?
  call checkRow
  add r8, rax

  mov rsi, 5 ; row 2?
  call checkRow
  add r8, rax

  mov rsi, 10 ; row 3?
  call checkRow
  add r8, rax

  mov rsi, 15 ; row 4?
  call checkRow
  add r8, rax

  mov rsi, 20 ; row 5?
  call checkRow
  add r8, rax
  
  mov rax, r8

  ret

;; rdi = board to check
;; rsi = column to check
;; returns 1 if won, 0 if not
;; clobbers rdx
checkColumn:
  mov rdx, 0
  mov rax, 0
  
  mov al, [rdi + rsi + 0]
  and al, 0x80
  add rdx, rax
  
  mov al, [rdi + rsi + 5]
  and al, 0x80
  add rdx, rax
  
  mov al, [rdi + rsi + 10]
  and al, 0x80
  add rdx, rax
  
  mov al, [rdi + rsi + 15]
  and al, 0x80
  add rdx, rax
  
  mov al, [rdi + rsi + 20]
  and al, 0x80
  add rdx, rax

  mov rax, 0
  cmp rdx, 0x80*5
  mov rdx, 1
  cmove rax, rdx
  ret

;; rdi = board to check
;; rsi = row to check * 5
;; returns 1 if won, 0 if not
;; clobbers rdx
checkRow:
  mov rdx, 0
  mov rax, 0

  mov al, [rdi + rsi + 0]
  and al, 0x80
  add rdx, rax

  mov al, [rdi + rsi + 1]
  and al, 0x80
  add rdx, rax

  mov al, [rdi + rsi + 2]
  and al, 0x80
  add rdx, rax

  mov al, [rdi + rsi + 3]
  and al, 0x80
  add rdx, rax

  mov al, [rdi + rsi + 4]
  and al, 0x80
  add rdx, rax

  mov rax, 0
  cmp rdx, 0x80*5
  mov rdx, 1
  cmove rax, rdx
  ret

;; rdi = board to sum
;; returns sum of unmarked spaces
;; clobbers rsi
sumBoard:
  mov rax, 0

  mov rcx, 25
.sumLoop:

  mov sil, [rdi + rcx - 1]
  test sil, 0x80
  jnz .continue
  
  movzx rsi, sil
  add rax, rsi

.continue:
  loop .sumLoop

  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
numbers:
  resb 100
boards:
  resb 100*25
won:
  resb 100