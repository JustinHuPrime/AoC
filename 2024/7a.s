extern exit, mmap, putlong, newline, atol, findc, findws

section .text

%define endOfFile r12
%define currChar r13
%define accumulator r14
%define currNum r15

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  lea endOfFile, [rax + rdx]

  ; parse and check each line of the solution
  mov accumulator, 0
.loop:

  ; clear
  mov rdi, numbers
  mov rcx, 128
  mov rax, 0
  rep stosq

  ; parse target
  mov rdi, currChar
  mov sil, `:`
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [target], rax

  add currChar, 2 ; skip `: `

  mov currNum, numbers
.readNumbersLoop:

  mov rdi, currChar
  call findws

  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [currNum], rax

  add currNum, 8
  inc currChar

  cmp BYTE [currChar - 1], `\n`
  jne .readNumbersLoop

  mov rdi, [numbers]
  lea rsi, [numbers + 8]
  call canMake

  mov rdi, accumulator
  add rdi, [target]
  test rax, rax
  cmovnz accumulator, rdi

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = current number
;; rsi = available numbers
;; returns if target can be made with rdi modified by adding or multiplying by numbers from rsi
;; structured as self-ref with lost-context accumulator
canMake:
  cmp QWORD [rsi], 0
  jne .hasNumbers

  mov rax, 0
  mov rdx, 1
  cmp rdi, [target]
  cmove rax, rdx
  ret

.hasNumbers:

  push rdi
  push rsi

  mov rax, rdi
  mul QWORD [rsi]
  mov rdi, rax
  lea rsi, [rsi + 8]
  call canMake

  pop rsi
  pop rdi

  test rax, rax
  jnz .return

  add rdi, [rsi]
  lea rsi, [rsi + 8]
  jmp canMake

.return:
  ret

section .bss
target: resq 1
numbers: resq 128
