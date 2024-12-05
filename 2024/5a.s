extern exit, mmap, putlong, newline, atol, findnl

section .text

%define endOfFile r12
%define currChar r13
%define currRule r14
%define currElement r15
%define nextElement rbp
%define accumulator rbx

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; read rules
  mov currRule, rules
.readRulesLoop:

  mov rdi, currChar
  lea rsi, [currChar + 2]
  call atol
  mov [currRule], al

  lea rdi, [currChar + 3]
  lea rsi, [currChar + 5]
  call atol
  mov [currRule + 1], al

  add currChar, 6
  add currRule, 2

  cmp BYTE [currChar], `\n`
  jne .readRulesLoop

  inc currChar

  ; for each line
  mov accumulator, 0
.readLineLoop:

  ; read it
  mov rdi, line
  mov rcx, 128
  mov al, 0
  rep stosb

  mov currElement, line
.readElementLoop:
  mov rdi, currChar
  lea rsi, [currChar + 2]
  call atol
  mov [currElement], al

  inc currElement
  add currChar, 3

  cmp BYTE [currChar - 1], `\n`
  jne .readElementLoop

  ; check if it follows the rules
  ; for each element
  mov currElement, line
.checkElementLoop:
  cmp BYTE [currElement], 0
  je .endCheckElementLoop

  ; and for each following element
  lea nextElement, [currElement + 1]
.checkElementPairLoop:
  cmp BYTE [nextElement], 0
  je .endCheckElementPairLoop

  ; does there exist a rule in the rules where the next element must be before this one?
  mov al, [nextElement]
  mov dl, [currElement]
  mov ah, dl
  mov rcx, 2048
  mov rdi, rules
  repne scasw
  je .continueLineLoop

  inc nextElement

  jmp .checkElementPairLoop
.endCheckElementPairLoop:

  inc currElement

  jmp .checkElementLoop
.endCheckElementLoop:

  ; get the middle element
  mov rsi, line
  lea rdi, [line + 1]
.getMiddleElementLoop:
  cmp BYTE [rdi], 0
  je .endGetMiddleElementLoop

  add rsi, 1
  add rdi, 2

  jmp .getMiddleElementLoop
.endGetMiddleElementLoop:

  ; found, add to accumulator
  mov al, [rsi]
  movzx rax, al
  add accumulator, rax

.continueLineLoop:
  cmp currChar, endOfFile
  jb .readLineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss
;; A rules entry, zero terminated list
;;
;; struct entry {
;;   BYTE before
;;   BYTE after
;; }
rules: resb 2 * 2048
;; The current line to operate on
line: resb 128
