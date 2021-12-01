section .text

;; rdi = start of string
;; rsi = end of string
;; returns integer value of string
;; clobbers rdi, rdx, rcx
atol:
  mov rax, 0 ; buffer = 0
  mov rdx, 10

  ; while current < end
.loop:
  cmp rdi, rsi
  jge .end

  imul rax, rdx ; rax *= 10

  mov cl, [rdi] ; rax += *current - '0'
  sub cl, '0'
  movzx rcx, cl
  add rax, rcx

  inc rdi ; ++current

  jmp .loop
.end:

  ret

;; rdi = start of string
;; returns pointer to newline
;; doesn't clobber
findNewline:
  mov rax, rdi

  ; while *rax != '\n'
.loop:
  cmp BYTE [rax], 0xa
  je .end

  inc rax ; ++rax
  
  jmp .loop
.end:

  ret

;; writeNewline:
;; clobbers rax, rdi, rsi, rdx
writeNewline:
  mov BYTE [writeBuf], 0xa

  mov rax, 1
  mov rdi, 1
  mov rsi, writeBuf
  mov rdx, 1
  syscall

  ret

;; rdi = unsigned long to write
;; clobbers rax, rdi, rsi, rdx
writeLong:
  ; special case: rdi = 0
  cmp rdi, 0
  jne .continue

  mov BYTE [writeBuf], '0'

  mov rax, 1
  mov rdi, 1
  mov rsi, writeBuf
  mov rdx, 1
  syscall

  ret

.continue:

  mov rax, rdi ; rax = number to write
  mov rdi, writeBufEnd ; rdi = start of string
  mov rsi, 10

  ; while rax != 0
.loop:
  test rax, rax
  jz .end

  dec rdi
  
  mov rdx, 0
  div rsi

  ; *rdi = (rax % 10) + '0'
  add dl, '0'
  mov [rdi], dl

  jmp .loop
.end:

  mov rax, 1 ; write buffer
  mov rsi, rdi
  mov rdi, 1
  mov rdx, writeBufEnd
  sub rdx, rsi
  syscall
  
  ret

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, rdonly
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statBuf
  syscall
  mov rdx, [statBuf + sizeOffset]
  mov r12, rdi

  mov rax, 12 ; save heap start in rbx
  mov rdi, 0
  syscall
  mov rbx, rax

  mov rax, 12 ; brk required space
  lea rdi, [rbx + rdx]
  syscall

  mov rax, 0 ; read file
  mov rdi, r12
  mov rsi, rbx
  ; mov rdx, rdx ; already have size in rdx
  syscall

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  ; mov rax, 1 ; write file as a check
  ; mov rdi, 1
  ; mov rsi, rbx
  ; ; mov rdx, rdx ; already have size in rdx
  ; syscall

  lea r12, [rbx + rdx] ; r12 = end of file
  mov r13, rbx ; r13 = current position

  mov rdi, r13
  call findNewline
  
  mov rsi, rax
  call atol
  mov r14, rax ; r14 = last value
  mov r15, 0 ; r15 = number of times increased

  ; while current < end
.loop:
  cmp r13, r12
  jge .end

  mov rdi, r13 ; get address of newline
  call findNewline

  mov rsi, rax ; get value of number
  call atol

  lea r11, [r15 + 1] ; if value > previous, increase count
  cmp rax, r14
  cmovg r15, r11

  ; push rsi ; display number as a check

  ; mov rdi, rax
  ; call writeLong
  ; call writeNewline
  
  ; pop rsi

  lea r13, [rsi + 1] ; current position = address of newline + 1
  mov r14, rax ; previous = value

  jmp .loop
.end:

  mov rdi, r15 ; print r15
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48
rdonly: equ 0

section .bss

statBuf:
  resb 144
writeBuf:
  resb 20
writeBufEnd: