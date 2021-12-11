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

  ; read input
  ; for each line
  mov rax, 0
.readLine:

  ; for each character
  mov rbx, 0
.readChar:

  mov cl, [r15] ; read character
  sub cl, '0' ; convert to number
  mov [buffer1 + rax + rbx], cl ; store in buffer1

  inc r15 ; next character
  inc rbx

  cmp rbx, 10
  jl .readChar

  inc r15 ; next line
  add rax, 10
  
  cmp rax, 10*10
  jl .readLine

  ; for 100 flashes
  mov r13, 0 ; r13 = number of flashes
  mov r14, buffer1
  mov r15, buffer2
  mov r12, 0
.simulateFlash:

  mov rdi, r15 ; count this step's flashes
  mov rsi, r14
  call step
  add r13, rax

  mov rdi, r14 ; swap buffers
  mov r14, r15
  mov r15, rdi

  inc r12
  cmp r12, 100
  jl .simulateFlash

  mov rdi, r13
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; rdi = destination buffer
;; rsi = source buffer
;; returns count of flashes this step
;; clobbers everything
step:
  mov rdx, rdi ; save destination buffer
  
  ; increase energy level by one
  mov rcx, 100
.increaseEnergy:
  lodsb
  inc al
  stosb
  loop .increaseEnergy

  mov rax, 0 ; rax = number of flashes
.flashLoop:
  mov cl, 0 ; cl = changed on this step?

  mov rsi, rdx ; rsi = buffer to work with
  mov r8, 0 ; r8 = y-coordinate
.yLoop:

  mov r9, 0 ; r9 = x-coordinate
.xLoop:

  mov dil, [rsi] ; get current cell
  cmp dil, 9 ; does it flash?
  jle .doneCell
  ; yes, flash

  mov BYTE [rsi], 0 ; expended energy
  inc rax ; one more flash
  mov cl, 1 ; mark as changed

  ; increment neighbors
  cmp r8, 0 ; top row?
  jle .skipTop

  cmp r9, 0 ; left column?
  jle .skipTopLeft

  mov dil, [rsi - 10 - 1] ; up one, left one
  test dil, dil
  jz .skipTopLeft ; zero = flashed already

  inc dil
  mov [rsi - 10 - 1], dil ; increment

.skipTopLeft:

  cmp r9, 9 ; right column?
  jge .skipTopRight

  mov dil, [rsi - 10 + 1] ; up one, right one
  test dil, dil
  jz .skipTopRight ; zero = flashed already

  inc dil
  mov [rsi - 10 + 1], dil ; increment

.skipTopRight:

  ; middle column
  mov dil, [rsi - 10] ; up one
  test dil, dil
  jz .skipTop ; zero = flashed already

  inc dil
  mov [rsi - 10], dil ; increment

.skipTop:

  cmp r8, 9 ; bottom row?
  jge .skipBottom
  
  cmp r9, 0 ; left column?
  jle .skipBottomLeft

  mov dil, [rsi + 10 - 1] ; down one, left one
  test dil, dil
  jz .skipBottomLeft ; zero = flashed already

  inc dil
  mov [rsi + 10 - 1], dil ; increment

.skipBottomLeft:

  cmp r9, 9 ; right column?
  jge .skipBottomRight

  mov dil, [rsi + 10 + 1] ; down one, right one
  test dil, dil
  jz .skipBottomRight ; zero = flashed already

  inc dil
  mov [rsi + 10 + 1], dil ; increment

.skipBottomRight:

  ; middle column
  mov dil, [rsi + 10] ; down one
  test dil, dil
  jz .skipBottom ; zero = flashed already

  inc dil
  mov [rsi + 10], dil ; increment

.skipBottom:

  ; middle row

  cmp r9, 0 ; left column?
  jle .skipLeft

  mov dil, [rsi - 1] ; left one
  test dil, dil
  jz .skipLeft ; zero = flashed already

  inc dil
  mov [rsi - 1], dil ; increment

.skipLeft:

  cmp r9, 9 ; right column?
  jge .doneCell

  mov dil, [rsi + 1] ; right one
  test dil, dil
  jz .doneCell ; zero = flashed already

  inc dil
  mov [rsi + 1], dil ; increment

.doneCell:

  inc rsi ; next byte
  inc r9

  cmp r9, 10
  jl .xLoop

  inc r8

  cmp r8, 10
  jl .yLoop

  test cl, cl
  jnz .flashLoop

  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
buffer1:
  resb 10*10
buffer2:
  resb 10*10