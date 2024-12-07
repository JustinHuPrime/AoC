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

  ; mul
  mov rax, rdi
  mul QWORD [rsi]
  mov rdi, rax
  lea rsi, [rsi + 8]
  call canMake

  pop rsi
  pop rdi

  test rax, rax
  jnz .return

  push rdi
  push rsi

  ; add
  add rdi, [rsi]
  lea rsi, [rsi + 8]
  call canMake

  pop rsi
  pop rdi

  test rax, rax
  jnz .return

  ; concat
  mov rdx, rdi
  mov rdi, [rsi]
  call log10
  mov rdi, rdx
  mul rdi
  mov rdi, rax
  add rdi, [rsi]
  lea rsi, [rsi + 8]
  jmp canMake

.return:
  ret

;; rdi = number
;; returns the multiplication required to concatenate this number
;; noclobber
log10:
  cmp rdi, 10
  jnb .next1

  mov rax, 10
  ret

.next1:
  cmp rdi, 100
  jnb .next2

  mov rax, 100
  ret

.next2:
  cmp rdi, 1000
  jnb .next3

  mov rax, 1000
  ret

.next3:
  cmp rdi, 10000
  jnb .next4

  mov rax, 10000
  ret

.next4:
  cmp rdi, 100000
  jnb .next5

  mov rax, 100000
  ret

.next5:
  cmp rdi, 1000000
  jnb .next6

  mov rax, 1000000
  ret

.next6:
  cmp rdi, 10000000
  jnb .next7

  mov rax, 10000000
  ret

.next7:
  cmp rdi, 100000000
  jnb .next8

  mov rax, 100000000
  ret

.next8:
  cmp rdi, 1000000000
  jnb .next9

  mov rax, 1000000000
  ret

.next9:
  mov rax, 10000000000
  cmp rdi, rax
  jnb .next10

  ret

.next10:
  mov rax, 100000000000
  cmp rdi, rax
  jnb .next11

  ret

.next11:
  mov rax, 1000000000000
  cmp rdi, rax
  jnb .next12

  ret

.next12:
  mov rax, 10000000000000
  cmp rdi, rax
  jnb .next13

  ret

.next13:
  mov rax, 100000000000000
  cmp rdi, rax
  jnb .next14

  ret

.next14:
  mov rax, 1000000000000000
  cmp rdi, rax
  jnb .next15

  ret

.next15:
  mov rax, 10000000000000000
  cmp rdi, rax
  jnb .next16

  ret

.next16:
  mov rax, 100000000000000000
  cmp rdi, rax
  jnb .next17

  ret

.next17:
  mov rax, 1000000000000000000
  cmp rdi, rax
  jnb .next18

  ret

.next18:
  mov rax, 10000000000000000000
  cmp rdi, rax
  jnb .next19

  ret

.next19:

  ud2

section .bss
target: resq 1
numbers: resq 128
