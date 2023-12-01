extern exit, mmap, isnum, findnl, putlong, newline

section .text

%define endOfFile r12
%define currLine r13
%define accumulator r14
%define currChar r15
%define currCharb r15b
%define endOfLine rbx

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov currLine, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
.lineLoop:

  ; find end of line
  mov rdi, currLine
  call findnl
  mov endOfLine, rax

  ; find the first number
  mov currChar, currLine
.findFirstLoop:

  ; if currChar is a digit
  mov dil, [currChar]
  call isnum
  test al, al
  jz .notDigitFirst

  ; add value * 10 to accumulator if so
  mov currCharb, [currChar]
  mov dil, currCharb
  sub currCharb, '0'
  movzx currChar, currCharb
  lea accumulator, [accumulator + currChar * 8]
  lea accumulator, [accumulator + currChar * 2]
  jmp .endFindFirstLoop

.notDigitFirst:

  ; if currChar is at least 3 from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 3
  jl .tooShortFirst

  ; and if the next four characters are 'one'
  cmp BYTE [currChar + 0], 'o'
  jne .not1First
  cmp BYTE [currChar + 1], 'n'
  jne .not1First
  cmp BYTE [currChar + 2], 'e'
  jne .not1First

  ; this is 'one'
  add accumulator, 10
  jmp .endFindFirstLoop

.not1First:

  ; and if the next four characters are 'two'
  cmp BYTE [currChar + 0], 't'
  jne .not2First
  cmp BYTE [currChar + 1], 'w'
  jne .not2First
  cmp BYTE [currChar + 2], 'o'
  jne .not2First

  ; this is 'two'
  add accumulator, 20
  jmp .endFindFirstLoop

.not2First:

  ; and if the next four characters are 'six'
  cmp BYTE [currChar + 0], 's'
  jne .not6First
  cmp BYTE [currChar + 1], 'i'
  jne .not6First
  cmp BYTE [currChar + 2], 'x'
  jne .not6First

  ; this is 'six'
  add accumulator, 60
  jmp .endFindFirstLoop

.not6First:

  ; else if currChar is at least 4 from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 4
  jl .tooShortFirst

  ; and if the next four characters are 'four'
  cmp BYTE [currChar + 0], 'f'
  jne .not4First
  cmp BYTE [currChar + 1], 'o'
  jne .not4First
  cmp BYTE [currChar + 2], 'u'
  jne .not4First
  cmp BYTE [currChar + 3], 'r'
  jne .not4First

  ; this is 'four'
  add accumulator, 40
  jmp .endFindFirstLoop

.not4First:

  ; and if the next four characters are 'five'
  cmp BYTE [currChar + 0], 'f'
  jne .not5First
  cmp BYTE [currChar + 1], 'i'
  jne .not5First
  cmp BYTE [currChar + 2], 'v'
  jne .not5First
  cmp BYTE [currChar + 3], 'e'
  jne .not5First

  ; this is 'five'
  add accumulator, 50
  jmp .endFindFirstLoop

.not5First:

  ; and if the next four characters are 'nine'
  cmp BYTE [currChar + 0], 'n'
  jne .not9First
  cmp BYTE [currChar + 1], 'i'
  jne .not9First
  cmp BYTE [currChar + 2], 'n'
  jne .not9First
  cmp BYTE [currChar + 3], 'e'
  jne .not9First

  ; this is 'nine'
  add accumulator, 90
  jmp .endFindFirstLoop

.not9First:

  ; else if currChar is at least 5 from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 5
  jl .tooShortFirst

  ; and if the next five characters are 'three'
  cmp BYTE [currChar + 0], 't'
  jne .not3First
  cmp BYTE [currChar + 1], 'h'
  jne .not3First
  cmp BYTE [currChar + 2], 'r'
  jne .not3First
  cmp BYTE [currChar + 3], 'e'
  jne .not3First
  cmp BYTE [currChar + 4], 'e'
  jne .not3First

  ; this is 'three'
  add accumulator, 30
  jmp .endFindFirstLoop

.not3First:

  ; or if the next five characters are 'seven'
  cmp BYTE [currChar + 0], 's'
  jne .not7First
  cmp BYTE [currChar + 1], 'e'
  jne .not7First
  cmp BYTE [currChar + 2], 'v'
  jne .not7First
  cmp BYTE [currChar + 3], 'e'
  jne .not7First
  cmp BYTE [currChar + 4], 'n'
  jne .not7First

  ; this is 'seven'
  add accumulator, 70
  jmp .endFindFirstLoop

.not7First:

  ; or if the next five characters are 'eight'
  cmp BYTE [currChar + 0], 'e'
  jne .not8First
  cmp BYTE [currChar + 1], 'i'
  jne .not8First
  cmp BYTE [currChar + 2], 'g'
  jne .not8First
  cmp BYTE [currChar + 3], 'h'
  jne .not8First
  cmp BYTE [currChar + 4], 't'
  jne .not8First

  ; this is 'eight'
  add accumulator, 80
  jmp .endFindFirstLoop

.not8First:

.tooShortFirst:

  inc currChar

  jmp .findFirstLoop
.endFindFirstLoop:

  ; find the last number
  lea currChar, [endOfLine - 1]
.findLastLoop:

  ; if currChar is a digit
  mov dil, [currChar]
  call isnum
  test al, al
  jz .notDigitLast

  ; add value to accumulator
  mov currCharb, [currChar]
  sub currCharb, '0'
  movzx currChar, currCharb
  add accumulator, currChar
  jmp .endFindLastLoop

.notDigitLast:

  ; else if currChar is at least 3 away from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 3
  jl .tooShortLast

  ; and if the next three characters are 'one'
  cmp BYTE [currChar + 0], 'o'
  jne .not1Last
  cmp BYTE [currChar + 1], 'n'
  jne .not1Last
  cmp BYTE [currChar + 2], 'e'
  jne .not1Last

  ; this is 'one'
  add accumulator, 1
  jmp .endFindLastLoop

.not1Last:

  ; and if the next three characters are 'two'
  cmp BYTE [currChar + 0], 't'
  jne .not2Last
  cmp BYTE [currChar + 1], 'w'
  jne .not2Last
  cmp BYTE [currChar + 2], 'o'
  jne .not2Last

  ; this is 'two'
  add accumulator, 2
  jmp .endFindLastLoop

.not2Last:

  ; and if the next three characters are 'six'
  cmp BYTE [currChar + 0], 's'
  jne .not6Last
  cmp BYTE [currChar + 1], 'i'
  jne .not6Last
  cmp BYTE [currChar + 2], 'x'
  jne .not6Last

  ; this is 'six'
  add accumulator, 6
  jmp .endFindLastLoop

.not6Last:

  ; else if currChar is at least 4 from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 4
  jl .tooShortLast

  ; and if the next four characters are 'four'
  cmp BYTE [currChar + 0], 'f'
  jne .not4Last
  cmp BYTE [currChar + 1], 'o'
  jne .not4Last
  cmp BYTE [currChar + 2], 'u'
  jne .not4Last
  cmp BYTE [currChar + 3], 'r'
  jne .not4Last

  ; this is 'four'
  add accumulator, 4
  jmp .endFindLastLoop

.not4Last:

  ; and if the next four characters are 'five'
  cmp BYTE [currChar + 0], 'f'
  jne .not5Last
  cmp BYTE [currChar + 1], 'i'
  jne .not5Last
  cmp BYTE [currChar + 2], 'v'
  jne .not5Last
  cmp BYTE [currChar + 3], 'e'
  jne .not5Last

  ; this is 'five'
  add accumulator, 5
  jmp .endFindLastLoop

.not5Last:

  ; and if the next four characters are 'nine'
  cmp BYTE [currChar + 0], 'n'
  jne .not9Last
  cmp BYTE [currChar + 1], 'i'
  jne .not9Last
  cmp BYTE [currChar + 2], 'n'
  jne .not9Last
  cmp BYTE [currChar + 3], 'e'
  jne .not9Last

  ; this is 'nine'
  add accumulator, 9
  jmp .endFindLastLoop

.not9Last:

  ; if currChar is at least 5 from the end of line
  mov rax, endOfLine
  sub rax, currChar
  cmp rax, 5
  jl .tooShortLast

  ; and if the next five characters are 'three'
  cmp BYTE [currChar + 0], 't'
  jne .not3Last
  cmp BYTE [currChar + 1], 'h'
  jne .not3Last
  cmp BYTE [currChar + 2], 'r'
  jne .not3Last
  cmp BYTE [currChar + 3], 'e'
  jne .not3Last
  cmp BYTE [currChar + 4], 'e'
  jne .not3Last

  ; this is 'three'
  add accumulator, 3
  jmp .endFindLastLoop

.not3Last:

  ; and if the next five characters are 'seven'
  cmp BYTE [currChar + 0], 's'
  jne .not7Last
  cmp BYTE [currChar + 1], 'e'
  jne .not7Last
  cmp BYTE [currChar + 2], 'v'
  jne .not7Last
  cmp BYTE [currChar + 3], 'e'
  jne .not7Last
  cmp BYTE [currChar + 4], 'n'
  jne .not7Last

  ; this is 'seven'
  add accumulator, 7
  jmp .endFindLastLoop

.not7Last:

  ; and if the next five characters are 'eight'
  cmp BYTE [currChar + 0], 'e'
  jne .not8Last
  cmp BYTE [currChar + 1], 'i'
  jne .not8Last
  cmp BYTE [currChar + 2], 'g'
  jne .not8Last
  cmp BYTE [currChar + 3], 'h'
  jne .not8Last
  cmp BYTE [currChar + 4], 't'
  jne .not8Last

  ; this is 'eight'
  add accumulator, 8
  jmp .endFindLastLoop

.not8Last:

.tooShortLast:

  dec currChar

  jmp .findLastLoop
.endFindLastLoop:

  mov currLine, endOfLine
  inc currLine

  cmp currLine, endOfFile
  jl .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit