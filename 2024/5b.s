extern exit, mmap, putlong, newline, atol, findnl, qsortby

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

  mov accumulator, 0
.readLineLoop:

  ; read it
  mov rdi, line
  mov rcx, 128
  mov rax, 0
  rep stosq

  mov currElement, line
.readElementLoop:
  mov rdi, currChar
  lea rsi, [currChar + 2]
  call atol
  mov [currElement], rax

  add currElement, 8
  add currChar, 3

  cmp BYTE [currChar - 1], `\n`
  jne .readElementLoop

  ; check if it follows the rules
  ; for each element
  mov currElement, line
.checkElementLoop:
  cmp QWORD [currElement], 0
  je .endCheckElementLoop

  ; and for each following element
  lea nextElement, [currElement + 8]
.checkElementPairLoop:
  cmp QWORD [nextElement], 0
  je .endCheckElementPairLoop

  ; does there exist a rule in the rules where the next element must be before this one?
  mov al, [nextElement]
  mov dl, [currElement]
  mov ah, dl
  mov rcx, 2048
  mov rdi, rules
  repne scasw
  je .fixLine

  add nextElement, 8

  jmp .checkElementPairLoop
.endCheckElementPairLoop:

  add currElement, 8

  jmp .checkElementLoop
.endCheckElementLoop:

  jmp .continueLineLoop
.fixLine:

  ; sort the line
  mov rdi, line
  lea rsi, [line + 128 * 8]
  mov rdx, compareByRules
  call qsortby

  ; get the middle element
  mov rsi, line
  lea rdi, [line + 8]
.getMiddleElementLoop:
  cmp QWORD [rdi], 0
  je .endGetMiddleElementLoop

  add rsi, 8
  add rdi, 16

  jmp .getMiddleElementLoop
.endGetMiddleElementLoop:

  ; found, add to accumulator
  add accumulator, [rsi]

.continueLineLoop:
  cmp currChar, endOfFile
  jb .readLineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = lhs
;; rsi = rhs
;; returns:
;; a negative number if lhs < rhs
;; 0 if lhs = rhs
;; a positive number if lhs > rhs
;; based on the page order rules
compareByRules:
  ; if rdi == rsi, equal
  cmp rdi, rsi
  je .equal

  ; sort 0 as greatest element
  test rdi, rdi
  jz .greater
  test rsi, rsi
  jz .less

  ; look up in rules list
  mov al, dil
  mov dl, sil
  mov ah, dl
  mov rcx, 2048
  mov rdi, rules
  repne scasw
  je .less ; there's a rule that rdi < rsi
  
  movbe [rsp - 2], ax
  mov ax, [rsp - 2]
  mov rcx, 2048
  mov rdi, rules
  repne scasw
  je .greater ; there's a rule that rdi > rsi

  ; no rules; return as equal

.equal:
  mov rax, 0
  ret
.less:
  mov rax, -1
  ret
.greater:
  mov rax, 1
  ret

section .bss
;; A rules entry, zero terminated list
;;
;; struct entry {
;;   BYTE before
;;   BYTE after
;; }
rules: resb 2 * 2048
;; The current line to operate on
line: resq 128
