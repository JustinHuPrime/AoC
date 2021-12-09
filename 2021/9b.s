section .text

extern writeNewline, writeLong, findWs, findChar

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

  ; initialize map to 9 everywhere
  mov al, 9
  mov rdi, map
  mov rcx, 102*102
  rep stosb

  ; read the map - for each of 100 lines
  mov rax, 102
.readLine:  

  mov rbx, 1
.readColumn:

  mov dil, [r15]
  sub dil, '0'
  mov [map + rax + rbx], dil

  inc r15 ; done with character

  inc rbx

  cmp rbx, 101
  jl .readColumn

  inc r15 ; skip newline

  add rax, 102

  cmp rax, 101*102
  jl .readLine

  mov r12, 0 ; r12 = next basin number

  ; find all 489 low points
  ; for each of the 100 lines
  mov r10, 102
.findLine:

  mov r11, 1
.findColumn:
  
  mov dil, [map + r10 + r11]
  cmp dil, [map + r10 + r11 + 1]
  jae .notLow
  cmp dil, [map + r10 + r11 - 1]
  jae .notLow
  cmp dil, [map + r10 + r11 + 102]
  jae .notLow
  cmp dil, [map + r10 + r11 - 102]
  jae .notLow

  lea rdi, [map + r10 + r11]
  mov [basins + (r12 * 8)], rdi
  inc r12

.notLow:

  inc r11

  cmp r11, 101
  jl .findColumn

  add r10, 102

  cmp r10, 101*102
  jl .findLine

  ; for each basin, convert it to a size
  mov rcx, r12
.countLoop:

  mov rdi, [basins + (rcx * 8) - 8]
  call countBasin
  mov [basins + (rcx * 8) - 8], rax

  loop .countLoop

  ; find the largest three basins
  mov rdi, 0 ; rdi = largest basin
  mov rsi, 0 ; rsi = second largest basin
  mov rdx, 0 ; rdx = third largest basin
  mov rcx, r12
.findLargest:

  mov rax, [basins + (rcx * 8) - 8]
  cmp rax, rdi
  cmovge rdx, rsi
  cmovge rsi, rdi
  cmovge rdi, rax
  jge .continue
  
  cmp rax, rsi
  cmovge rdx, rsi
  cmovge rsi, rax
  jge .continue

  cmp rax, rdx
  cmovge rdx, rax

.continue:

  loop .findLargest

  imul rdi, rsi
  imul rdi, rdx

  ; mov rdi, rdi
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; rdi = basin address
;; returns size of basin
;; clobbers map, rsi, rdx
countBasin:
  mov sil, [rdi]
  cmp sil, 9
  je .baseCase

  mov BYTE [rdi], 9 ; mark current space as counted

  sub rsp, 24
  mov QWORD [rsp + 0], 1
  mov [rsp + 8], rdi
  mov [rsp + 16], sil

  ; consider up
  mov dl, [rdi - 102]
  cmp sil, dl
  jge .skipUp

  sub rdi, 102
  call countBasin
  add [rsp + 0], rax
  mov rdi, [rsp + 8]
  mov sil, [rsp + 16]

.skipUp:

  ; consider down
  mov dl, [rdi + 102]
  cmp sil, dl
  jge .skipDown

  add rdi, 102
  call countBasin
  add [rsp + 0], rax
  mov rdi, [rsp + 8]
  mov sil, [rsp + 16]

.skipDown:

  ; consider left
  mov dl, [rdi - 1]
  cmp sil, dl
  jge .skipLeft

  sub rdi, 1
  call countBasin
  add [rsp + 0], rax
  mov rdi, [rsp + 8]
  mov sil, [rsp + 16]

.skipLeft:

  ; consider right
  mov dl, [rdi + 1]
  cmp sil, dl
  jge .skipRight

  add rdi, 1
  call countBasin
  add [rsp + 0], rax

.skipRight:

  mov rax, [rsp + 0]

  add rsp, 24

  ret

.baseCase:
  mov rax, 0

  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
map:
  resb 102*102
basins:
  resq 220