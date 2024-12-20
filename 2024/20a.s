extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define endPos QWORD [rsp + 8]

%define todoHead r12

%define threshold 100 + 2
; %define threshold 20 + 2

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov al, '#'
  mov rdi, map
  mov rcx, 256 * 256
  rep stosb

  ; read map
  mov rdi, 0
.readLoop:

  mov rsi, rdi
.readLineLoop:

  mov al, [currChar]
  mov [map + rsi], al

  cmp al, 'E'
  jne .continueReadLineLoop

  mov endPos, rsi

.continueReadLineLoop:

  inc currChar
  inc rsi

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  add rdi, 256

  cmp currChar, endOfFile
  jb .readLoop

  ; initialize fastest path
  mov rax, 0x7fffffffffffffff
  mov rdi, fastestPath
  mov rcx, 256 * 256
  rep stosq

  mov todoHead, todo
  mov rax, endPos
  mov [todoHead + 0 * 8], rax
  mov QWORD [todoHead + 1 * 8], 0
  add todoHead, 2 * 8
.traverseFastestPathLoop:
  sub todoHead, 2 * 8
  mov rdi, [todoHead + 0 * 8]
  mov rsi, [todoHead + 1 * 8]

  ; have we been here for equivalent or cheaper?
  cmp rsi, [fastestPath + rdi * 8]
  jae .continueTraverseFastestPathLoop

  ; we have not; save the new cost to get here
  mov [fastestPath + rdi * 8], rsi

  ; consider moving around
  inc rsi

  cmp BYTE [map + rdi - 256], '#'
  je .notTraverseFastestPathUp

  lea rax, [rdi - 256]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rsi
  add todoHead, 2 * 8

.notTraverseFastestPathUp:

  cmp BYTE [map + rdi + 256], '#'
  je .notTraverseFastestPathDown

  lea rax, [rdi + 256]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rsi
  add todoHead, 2 * 8

.notTraverseFastestPathDown:

  cmp BYTE [map + rdi - 1], '#'
  je .notTraverseFastestPathLeft

  lea rax, [rdi - 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rsi
  add todoHead, 2 * 8

.notTraverseFastestPathLeft:

  cmp BYTE [map + rdi + 1], '#'
  je .notTraverseFastestPathRight

  lea rax, [rdi + 1]
  mov [todoHead + 0 * 8], rax
  mov [todoHead + 1 * 8], rsi
  add todoHead, 2 * 8

.notTraverseFastestPathRight:

.continueTraverseFastestPathLoop:
  cmp todoHead, todo
  ja .traverseFastestPathLoop

  mov rax, 0
  mov rdi, 0
.countCheatLoop:

  ; is this even a valid spot to start a cheat?
  cmp BYTE [map + rdi], '#'
  je .continueCountCheatLoop

  ; consider cheats

  ; left down
  lea rsi, [rdi - 1 + 256]
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notLeftDown

  inc rax

.notLeftDown:

  ; left left
  lea rsi, [rdi - 2]
  test rsi, rsi
  js .notLeftLeft
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notLeftLeft

  inc rax

.notLeftLeft:

  ; left up
  lea rsi, [rdi - 1 - 256]
  test rsi, rsi
  js .notLeftUp
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notLeftUp

  inc rax

.notLeftUp:

  ; up up
  lea rsi, [rdi - 512]
  test rsi, rsi
  js .notUpUp
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notUpUp

  inc rax

.notUpUp:

  ; right up
  lea rsi, [rdi + 1 - 256]
  test rsi, rsi
  js .notRightUp
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notRightUp

  inc rax

.notRightUp:

  ; right right
  lea rsi, [rdi + 2]
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notRightRight

  inc rax

.notRightRight:

  ; right down
  lea rsi, [rdi + 1 + 256]
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notRightDown

  inc rax

.notRightDown:

  ; down down
  lea rsi, [rdi + 512]
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]
  cmp rdx, threshold
  jl .notDownDown

  inc rax

.notDownDown:

.continueCountCheatLoop:
  inc rdi

  cmp rdi, 256 * 256
  jb .countCheatLoop

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
map: resb 256 * 256
fastestPath: resq 256 * 256
todo: resq 2 * 256 * 256