extern exit, mmap, putlong, newline, findc, atol, alloc, findnl, isnum, findnotnum

section .text

%define accumulator r15
%define parsed rbx
%define currChar r12
%define endOfFile [rsp + 0]
%define size [rsp + 8]
%define currCell r13
%define numLength r15
%define x r13
%define y r14
%define sizer r12
%define negsizer rdi

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 8 * 8
  ;; slots:
  ;; rsp + 0 = endOfFile
  ;; rsp + 8 = size
  ;; rsp + 16, 24, 32, 40, 48, 56 = adjacency cells

  mov currChar, rax
  lea rdi, [rax + rdx]
  mov endOfFile, rdi

  ; find size of grid
  mov rdi, currChar
  call findnl
  sub rax, rdi
  mov size, rax

  ; allocate the grid, pretending that it's 2 spaces wider than it actually is
  mov rdi, size
  add rdi, 2
  imul rdi, rdi
  shl rdi, 1 ; allocate words
  mov r14, rdi ; r14 = size to zero
  call alloc

  mov parsed, rax

  ; clear allocated region
  mov rdi, rax
  mov rcx, r14
  shr rcx, 1
  mov ax, 0x8000
  rep stosw

  ; skip first line padding and left padding
  add parsed, size
  add parsed, size
  add parsed, 6

  mov currCell, parsed
  ; for each character
.parseLoop:

  ; consider the current character
  ; is it a newline
  cmp BYTE [currChar], 0xa
  jne .notNewline

  ; skip one character and two padding cells
  inc currChar
  add currCell, 4

  jmp .continueLineLoop
.notNewline:

  ; is it a dot
  cmp BYTE [currChar], '.'
  jne .notDot

  ; store a zero symbol
  mov ax, 0x8000
  mov [currCell], ax
  inc currChar
  add currCell, 2

  jmp .continueLineLoop
.notDot:

  ; is it a digit
  mov dil, [currChar]
  call isnum
  test al, al
  jz .notNumber

  ; parse it
  mov rdi, currChar
  call findnotnum

  mov numLength, rax
  sub numLength, currChar
  
  mov rdi, currChar
  mov rsi, rax
  call atol

  ; store it into the next numLength cells
.storeLoop:

  mov [currCell], ax
  add currCell, 2
  inc currChar

  dec numLength

  test numLength, numLength
  jnz .storeLoop

  jmp .continueLineLoop
.notNumber:

  ; copy but set first bit
  mov al, [currChar]
  movzx ax, al
  or ax, 0x8000
  mov [currCell], ax
  inc currChar
  add currCell, 2

.continueLineLoop:

  cmp currChar, endOfFile
  jb .parseLoop

  ; done parsing, traverse array

  mov accumulator, 0
  mov sizer, size
  mov negsizer, sizer
  neg negsizer

  ; do-while y < size
  mov y, 0
.yLoop:

  mov x, 0
.xLoop:

  ; consider current cell - is it a star?
  cmp WORD [parsed], '*' | 0x8000
  jne .notGear

  ; count adjacent numbers and record them
  mov rbp, 0 ; rbp = count of adjacent numbers
  mov QWORD [rsp + 16], 1 ; slots to store adjacent numbers
  mov QWORD [rsp + 24], 1
  mov QWORD [rsp + 32], 1
  mov QWORD [rsp + 40], 1
  mov QWORD [rsp + 48], 1
  mov QWORD [rsp + 56], 1
  
  ; check top
  mov ax, [parsed + negsizer * 2 - 4]
  test ax, ax
  js .topNotNumber

  ; top is number
  inc rbp
  movzx rax, ax
  mov [rsp + 16], rax

  jmp .doneTop
.topNotNumber:

  ; top is not number - check top left, top right
  mov ax, [parsed + negsizer * 2 - 6]
  test ax, ax
  js .topLeftNotNumber
  
  ; top left is number
  inc rbp
  movzx rax, ax
  mov [rsp + 16], rax

.topLeftNotNumber:

  mov ax, [parsed + negsizer * 2 - 2]
  test ax, ax
  js .topRightNotNumber

  ; top right is number
  inc rbp
  movzx rax, ax
  mov [rsp + 24], rax

.topRightNotNumber:

.doneTop:

  ; check bottom
  mov ax, [parsed + sizer * 2 + 4]
  test ax, ax
  js .bottomNotNumber

  ; bottom is number
  inc rbp
  movzx rax, ax
  mov [rsp + 32], rax

  jmp .doneBottom
.bottomNotNumber:

  ; bottom is not number - check bottom left, bottom right
  mov ax, [parsed + sizer * 2 + 2]
  test ax, ax
  js .bottomLeftNotNumber

  ; bottom left is number
  inc rbp
  movzx rax, ax
  mov [rsp + 32], rax

.bottomLeftNotNumber:

  mov ax, [parsed + sizer * 2 + 6]
  test ax, ax
  js .bottomRightNotNumber

  ; bottom right is number
  inc rbp
  movzx rax, ax
  mov [rsp + 40], rax

.bottomRightNotNumber:

.doneBottom:

  ; check left, right
  mov ax, [parsed - 2]
  test ax, ax
  js .leftNotNumber

  ; left is number
  inc rbp
  movzx rax, ax
  mov [rsp + 48], rax

.leftNotNumber:

  mov ax, [parsed + 2]
  test ax, ax
  js .rightNotNumber

  ; right is number
  inc rbp
  movzx rax, ax
  mov [rsp + 56], rax

.rightNotNumber:

  cmp rbp, 2
  jne .notGear

  ; is gear - calculate gear ratio and add to accumulator
  mov rax, [rsp + 16]
  imul rax, [rsp + 24]
  imul rax, [rsp + 32]
  imul rax, [rsp + 40]
  imul rax, [rsp + 48]
  imul rax, [rsp + 56]
  add accumulator, rax

.notGear:

  inc x
  add parsed, 2

  cmp x, sizer
  jb .xLoop

  inc y
  add parsed, 4

  cmp y, sizer
  jb .yLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit
