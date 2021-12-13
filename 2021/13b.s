section .text

extern writeNewline, writeLong, findChar, atol

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

  mov r14, 0
.readDotLoop:

  mov rdi, r15 ; get x
  mov sil, ','
  call findChar
  mov rsi, rax
  call atol
  mov [dots + (r14 * 8) + 0], eax

  lea rdi, [rsi + 1] ; get y
  mov sil, 0xa
  call findChar
  mov rsi, rax
  call atol
  mov [dots + (r14 * 8) + 4], eax

  lea r15, [rsi + 1] ; done with this line
  inc r14

  cmp r14, 823
  jl .readDotLoop

  inc r15 ; skip blank line

  mov r14, 0
.readFoldLoop:

  add r15, 11 ; move to the direction
  mov dil, [r15]
  cmp dil, 'y'
  mov esi, 0 ; 0 = x, 1 = y
  mov edi, 1
  cmove esi, edi
  mov [folds + (r14 * 8) + 0], esi

  add r15, 2 ; move to the number
  mov rdi, r15
  mov sil, 0xa
  call findChar
  mov rsi, rax
  call atol
  mov [folds + (r14 * 8) + 4], eax

  lea r15, [rsi + 1] ; done with this line

  inc r14

  cmp r14, 12
  jl .readFoldLoop

  ; apply all folds
  mov r15, 0
.foldLoop:

  mov eax, [folds + (r15 * 8) + 0]
  test eax, eax
  mov rax, foldX
  mov rdi, foldY
  cmovnz rax, rdi
  mov edi, [folds + (r15 * 8) + 4]
  call rax

  inc r15

  cmp r15, 12
  jl .foldLoop

  ; find the maximum x and y
  mov r8d, 0 ; r10 = max x
  mov r9d, 0 ; r12 = max y
  mov r15, 0
.maxLoop:

  mov edi, [dots + (r15 * 8) + 0]
  cmp edi, r8d
  cmovg r8d, edi

  mov edi, [dots + (r15 * 8) + 4]
  cmp edi, r9d
  cmovg r9d, edi

  inc r15

  cmp r15, 823
  jl .maxLoop

  ; put a newline after the maxmimum x
  mov BYTE [lineBuffer + r8 + 1], 0xa

  ; for each y-value from 0 to max y
  mov r10d, 0
.lineLoop:

  ; clear the line buffer
  mov al, ' '
  mov rdi, lineBuffer
  lea rcx, [r8 + 1]
  rep stosb

  ; for each point
  mov r15, 0
.pointLoop:

  mov edi, [dots + (r15 * 8) + 4] ; get the y-value
  cmp edi, r10d ; is it the current y-value?
  jne .continue

  ; is the current y-value

  mov edi, [dots + (r15 * 8) + 0] ; get the x-value
  mov BYTE [lineBuffer + rdi], '#' ; put a star in the line buffer

.continue:

  inc r15

  cmp r15, 823
  jl .pointLoop

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, lineBuffer ; from the line buffer
  lea rdx, [r8 + 2] ; length of the line
  syscall

  inc r10

  cmp r10, r9
  jle .lineLoop

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; folds across y = edi
;; edi = fold coordinate
;; clobbers everything
foldY:
  mov rsi, 0 ; for each point
.loop:

  mov eax, [dots + (rsi * 8) + 4] ; get the y coordinate
  cmp eax, edi
  jle .continue

  ; is below the fold - fold it up

  mov edx, edi ; fold y
  shl edx, 1 ; times two
  sub edx, eax ; minus original y
  mov [dots + (rsi * 8) + 4], edx ; gets stored

.continue:

  inc rsi

  cmp rsi, 823
  jl .loop

  ret

;; fold across x = edi
;; edi = fold coordinate
;; clobbers everything
foldX:
  mov rsi, 0 ; for each point
.loop:

  mov eax, [dots + (rsi * 8) + 0] ; get the x coordinate
  cmp eax, edi
  jle .continue

  ; is right of the fold - fold it left

  mov edx, edi ; fold x
  shl edx, 1 ; times two
  sub edx, eax ; minus original x
  mov [dots + (rsi * 8) + 0], edx ; gets stored

.continue:

  inc rsi

  cmp rsi, 823
  jl .loop

  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
;; struct dots {
;;   unsigned int x;
;;   unsigned int y;
;; }
dots:
  resd 823*2
folds:
  resd 12*2
lineBuffer:
  resb 1024