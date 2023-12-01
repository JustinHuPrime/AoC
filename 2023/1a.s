extern exit, mmap, isnum, findnl, putlong, newline

section .text

%define endOfFile r12
%define currLine r13
%define accumulator r14
%define currChar r15
%define currCharb r15b
%define endOfLine r13

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currLine, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
.lineLoop:

  ; for currChar = currLine; !isnum *currChar; ++currChar
  mov currChar, currLine
.findFirstLoop:
  mov dil, [currChar]
  call isnum
  test al, al
  jnz .endFindFirstLoop

  inc currChar

  jmp .findFirstLoop
.endFindFirstLoop:

  ; currChar = *currChar - '0'
  mov currCharb, [currChar]
  sub currCharb, '0'
  movzx currChar, currCharb

  ; accumulator += currChar * 10
  lea accumulator, [accumulator + currChar * 8]
  lea accumulator, [accumulator + currChar * 2]

  ; endOfLine = findnl(currLine)
  mov rdi, currLine
  call findnl
  mov endOfLine, rax

  ; for currChar = endOfLine - 1; !isnum *currChar; --currChar
  lea currChar, [endOfLine - 1]
.findLastLoop:
  mov dil, [currChar]
  call isnum
  test al, al
  jnz .endFindLastLoop

  dec currChar

  jmp .findLastLoop
.endFindLastLoop:

  ; currChar = *currChar - '0'
  mov currCharb, [currChar]
  sub currCharb, '0'

  ; accumulator += currChar
  movzx currChar, currCharb
  add accumulator, currChar

  ; currLine = endOfLine + 1
  inc endOfLine
  ; mov currLine, endOfLine

  cmp currLine, endOfFile
  jl .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit