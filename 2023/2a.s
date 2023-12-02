extern exit, mmap, putlong, newline, findc, atol, findspace

section .text

%define curr r12
%define endOfFile r13
%define accumulator rbx
%define id [rsp + 0 * 8]
%define red [rsp + 1 * 8]
%define green [rsp + 2 * 8]
%define blue [rsp + 3 * 8]
%define count rax

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 8 * 4
  ;; slots:
  ;; id = rsp + 0
  ;; red = rsp + 8
  ;; green = rsp + 16
  ;; blue = rsp + 24

  mov curr, rax
  lea endOfFile, [rax + rdx]

  ; do-while curr < endOfFile
.lineLoop:

  ; skip "Game "
  add curr, 5

  ; read id
  mov rdi, curr
  mov sil, ':'
  call findc
  mov curr, rax
  mov rsi, rax
  call atol
  mov id, rax

  ; skip ": "
  add curr, 2

  mov QWORD red, 0
  mov QWORD green, 0
  mov QWORD blue, 0

  ; do while curr is not a newline
.setLoop:

  ; do while curr is not a semicolon and not a newline
.cubeLoop:

  ; read count
  mov rdi, curr
  call findspace
  mov curr, rax
  mov rsi, rax
  call atol
  ; mov count, rax ; count = rax

  ; skip " "
  inc curr

  ; check colour
  cmp BYTE [curr], 'r'
  jne .notRed

  ; skip "red"
  add curr, 3

  ; if count > red
  cmp count, red
  jng .endColours

  mov red, count

  jmp .endColours
.notRed:

  cmp BYTE [curr], 'g'
  jne .notGreen

  ; skip "green"
  add curr, 5

  ; if count > green
  cmp count, green
  jng .endColours

  mov green, count

  jmp .endColours
.notGreen:

  ; must be blue

  ; skip "blue"
  add curr, 4

  ; if count > blue
  cmp count, blue
  jng .endColours

  mov blue, count

.endColours:

  cmp BYTE [curr], ';'
  je .endCubeLoop
  cmp BYTE [curr], 0xa
  je .endCubeLoop

  ; skip ", "
  add curr, 2

  jmp .cubeLoop
.endCubeLoop:

  cmp BYTE [curr], 0xa
  je .endSetLoop

  ; skip "; "
  add curr, 2

  jmp .setLoop
.endSetLoop:

  ; skip "\n"
  inc curr

  ; check if game is possible, add to accumulator if so
  cmp QWORD red, 12
  jg .notPossible
  cmp QWORD green, 13
  jg .notPossible
  cmp QWORD blue, 14
  jg .notPossible

  add accumulator, id

.notPossible:

  cmp curr, endOfFile
  jl .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit