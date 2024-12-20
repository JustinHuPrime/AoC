extern exit, mmap, putlong, newline

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define endPos QWORD [rsp + 8]

%define todoHead r12

%define threshold 100
; %define threshold 77

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
  mov r9, -20 * 256 ; r9 = y offset
.countYLoop:

  mov rdx, r9
  neg rdx
  test rdx, rdx
  cmovs rdx, r9
  shr rdx, 8

  mov r8, 20
  sub r8, rdx
  neg r8 ; r8 = x offset
.countXLoop:

  ; will this take us off scale
  mov rsi, rdi
  add rsi, r8
  add rsi, r9
  test rsi, rsi
  js .continueCountElementLoop

  ; is this fast enough
  mov rdx, [fastestPath + rdi * 8]
  sub rdx, [fastestPath + rsi * 8]

  mov rcx, threshold

  mov r10, r8
  neg r10
  test r10, r10
  cmovs r10, r8
  add rcx, r10

  mov r10, r9
  neg r10
  test r10, r10
  cmovs r10, r9
  shr r10, 8
  add rcx, r10
  
  cmp rdx, rcx
  jl .continueCountElementLoop

  inc rax

.continueCountElementLoop:
  inc r8

  mov rdx, r9
  neg rdx
  test rdx, rdx
  cmovs rdx, r9
  shr rdx, 8
  mov rcx, 20
  sub rcx, rdx

  cmp r8, rcx
  jle .countXLoop

  add r9, 256
  cmp r9, 20 * 256
  jle .countYLoop

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