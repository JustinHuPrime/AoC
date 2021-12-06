section .text

extern writeNewline, writeLong, atol, findComma, findWs

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

  ; for each of the 500 lines
  mov r14, 0
.loop:

  mov rdi, r15 ; read the x of the first point
  call findComma
  mov rsi, rax
  call atol
  mov r8, rax ; r8 = point1.x

  lea rdi, [rsi + 1] ; skip comma
  call findWs ; read the y of the first point
  mov rsi, rax
  call atol
  mov r9, rax ; r9 = point1.y

  lea rdi, [rsi + 4] ; skip the arrow
  call findComma ; read the x of the second point
  mov rsi, rax
  call atol
  mov r10, rax ; r10 = point2.x

  lea rdi, [rsi + 1] ; skip comma
  call findWs ; read the y of the second point
  mov rsi, rax
  call atol
  mov r11, rax ; r11 = point2.y

  lea r15, [rsi + 1] ; skip the newline

  imul r9, 1000 ; r9 = y offset
  imul r11, 1000 ; r11 = y offset

  cmp r8, r10 ; point1.x == point2.x ?
  jne .notHorizontal
  ; yes - horizontal line between min(point1.y, point2.y) and max(point1.y, point2.y)

  mov r10, r9
  cmp r11, r9
  cmovl r9, r11 ; r9 = start
  cmovl r11, r10 ; r11 = end
.writeYLoop:
  inc BYTE [map + r8 + r9]

  add r9, 1000

  cmp r9, r11
  jle .writeYLoop

  jmp .doneMarking
.notHorizontal:

  cmp r9, r11 ; point1.y == point2.y ?
  jne .notVertical
  ; yes - vertical line between min(point1.x, point2.x) and max(point1.x, point2.x)

  mov r11, r8
  cmp r10, r8
  cmovl r8, r10 ; r8 = start
  cmovl r10, r11 ; r10 = end

.writeXLoop:
  inc BYTE [map + r9 + r8]
  
  inc r8

  cmp r8, r10
  jle .writeXLoop

  jmp .doneMarking
.notVertical:

  ; make point1 the left point
  cmp r8, r10
  jl .noMove

  mov r12, r10 ; swap x
  mov r10, r8
  mov r8, r12
  
  mov r12, r11 ; swap y
  mov r11, r9
  mov r9, r12

.noMove:

  ; r8 = start x
  ; r9 = start y offset
  ; r10 = end x
  ; r11 = end y offset

  ; is this headed upwards or downwards?
  cmp r9, r11
  jg .upwards
  ; downwards

.writeDownLoop:

  inc BYTE [map + r9 + r8]

  inc r8
  add r9, 1000

  cmp r8, r10
  jle .writeDownLoop

  jmp .doneMarking
.upwards:
  ; upwards

.writeUpLoop:

  inc BYTE [map + r9 + r8]

  inc r8
  sub r9, 1000

  cmp r8, r10
  jle .writeUpLoop

  ; fallthrough
.doneMarking:

  inc r14

  cmp r14, 500
  jl .loop

  mov rdi, 0 ; rdi = number of intersections

  mov rcx, 1000*1000
.countLoop:

  lea rsi, [rdi + 1]
  cmp BYTE [map + rcx - 1], 2
  cmovge rdi, rsi

  loop .countLoop

  ; mov rdi, rdi ; already have number of intersections
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
map:
  resb 1000*1000