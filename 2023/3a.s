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

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots:
  ;; rsp + 0 = endOfFile
  ;; rsp + 8 = size

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
  imul rdi, 2 ; allocate words
  mov r14, rdi ; r14 = size to zero
  call alloc

  mov parsed, rax

  ; zero allocated region
  mov rdi, rax
  mov rcx, r14
  mov al, 0
  rep stosb

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

  ; skip
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

  ; do-while y < size
  mov y, 0
.yLoop:

  mov x, 0
.xLoop:

  ; consider current cell - is the leading bit set
  bt WORD [parsed], 15
  jnc .notSymbol

  ; add left, right, top, bottom
  movzx rax, WORD [parsed - 2]
  add accumulator, rax
  movzx rax, WORD [parsed + 2]
  add accumulator, rax
  mov rdi, sizer
  neg rdi
  movzx rax, WORD [parsed + 2 * rdi - 4]
  add accumulator, rax
  movzx rax, WORD [parsed + 2 * sizer + 4]
  add accumulator, rax

  ; check - was top a number? skip top left and top right if so
  mov ax, WORD [parsed + 2 * rdi - 4]
  test ax, ax
  jnz .skipTop

  ; add top left, top right
  movzx rax, WORD [parsed + 2 * rdi - 6]
  add accumulator, rax
  movzx rax, WORD [parsed + 2 * rdi - 2]
  add accumulator, rax

.skipTop:

  ; check - was bottom a number? skip bottom left and bottom right if so
  mov ax, WORD [parsed + 2 * sizer + 4]
  test ax, ax
  jnz .skipBottom

  movzx rax, WORD [parsed + 2 * sizer + 2]
  add accumulator, rax
  movzx rax, WORD [parsed + 2 * sizer + 6]
  add accumulator, rax

.skipBottom:

.notSymbol:

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