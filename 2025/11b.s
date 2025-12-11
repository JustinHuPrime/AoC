extern mmap, putlong, newline, exit, alloc, findc, countc

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define transitions r13
%define svr (('s' - 'a') * 26 * 26 + ('v' - 'a') * 26 + ('r' - 'a'))
%define out (('o' - 'a') * 26 * 26 + ('u' - 'a') * 26 + ('t' - 'a'))
%define dac (('d' - 'a') * 26 * 26 + ('a' - 'a') * 26 + ('c' - 'a'))
%define fft (('f' - 'a') * 26 * 26 + ('f' - 'a') * 26 + ('t' - 'a'))
%define accumulatorSvrDac [rsp + 8]
%define accumulatorSvrFft [rsp + 16]
%define accumulatorDacFft [rsp + 24]
%define accumulatorFftDac [rsp + 32]
%define accumulatorDacOut [rsp + 40]
%define accumulatorFftOut [rsp + 48]
%define todo r14

;; struct Todo {
;;   location: u64
;;   next: *Todo
;; }
%define sizeofTodo (2 * 8)
%define offsetofTodoLocation 0
%define offsetofTodoNext 8
%define seenDacMask (1 << 0)
%define seenFftMask (1 << 1)

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 7 * 8
  ;; slots
  ;; rsp + 48, accumulatorFftOut
  ;; rsp + 40, accumulatorDacOut
  ;; rsp + 32, accumulatorFftDac
  ;; rsp + 24, accumulatorDacFft
  ;; rsp + 16, accumulatorSvrFft
  ;; rsp + 8, accumulatorSvrDac
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  ; allocate transitions array
  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov transitions, rax

.parseLoop:
  mov rdi, currChar
  call parseWord
  lea rbx, [transitions + 8 * rax] ; rbx = pointer to transitions entry

  add currChar, 4
  mov rdi, currChar
  mov sil, `\n`
  call findc
  mov rdi, currChar
  mov rsi, rax
  mov dl, ' '
  call countc
  lea rdi, [8 * rax + 8]
  call alloc
  mov [rbx], rax ; store pointer to transitions list

  inc currChar

  mov rbx, rax ; rbx = pointer to transitions list
.parseDestinations:

  mov rdi, currChar
  call parseWord
  mov [rbx], rax

  add rbx, 8
  add currChar, 4

  cmp BYTE [currChar - 1], `\n`
  jne .parseDestinations

  cmp currChar, endOfFile
  jb .parseLoop

  ; count paths (memoized)
  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, svr
  mov rsi, dac
  mov rdx, transitions
  call countPaths
  mov accumulatorSvrDac, rax

  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, dac
  mov rsi, fft
  mov rdx, transitions
  call countPaths
  mov accumulatorDacFft, rax

  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, fft
  mov rsi, out
  mov rdx, transitions
  call countPaths
  mov accumulatorFftOut, rax

  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, svr
  mov rsi, fft
  mov rdx, transitions
  call countPaths
  mov accumulatorSvrFft, rax

  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, fft
  mov rsi, dac
  mov rdx, transitions
  call countPaths
  mov accumulatorFftDac, rax

  mov rdi, (26 * 26 * 26) * 8
  call alloc
  mov rdi, rax
  mov rsi, rax
  mov rcx, (26 * 26 * 26) * 8
  mov rax, -1
  rep stosq
  mov rcx, rsi
  mov rdi, dac
  mov rsi, out
  mov rdx, transitions
  call countPaths
  mov accumulatorDacOut, rax
  
  ; result = svr->dac * dac->fft * fft->out + svr->fft * fft->dac * dac->out

  mov rax, accumulatorSvrDac
  mov rdx, accumulatorDacFft
  mul rdx
  mov rdx, accumulatorFftOut
  mul rdx
  mov rdi, rax

  mov rax, accumulatorSvrFft
  mov rdx, accumulatorFftDac
  mul rdx
  mov rdx, accumulatorDacOut
  mul rdx
  add rdi, rax

  ; mov rdi, rdi
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = pointer to word
;; returns word as number
parseWord:
  movzx rdx, BYTE [rdi]
  sub rdx, 'a'
  mov rax, rdx
  mov rdx, 26
  mul rdx

  movzx rdx, BYTE [rdi + 1]
  sub rdx, 'a'
  add rax, rdx
  mov rdx, 26
  mul rdx

  movzx rdx, BYTE [rdi + 2]
  sub rdx, 'a'
  add rax, rdx
  ret

;; rdi = current word
;; rsi = target word
;; rdx = transitions
;; rcx = memoization
;; counts number of ways to get from current to target, memoized
countPaths:
  mov r8, [rcx + 8 * rdi]
  cmp r8, -1
  je .notMemoized

  mov rax, r8
  ret

.notMemoized:

  ; base case - are we at the target already?
  cmp rdi, rsi
  jne .notAtTarget

  ; only one way to not make any moves
  mov rax, 1
  mov [rcx + 8 * rdi], rax
  ret

.notAtTarget:

  ; base case - are there no transitions?
  mov r8, [rdx + 8 * rdi]
  test r8, r8
  jnz .hasTransitions

  ; no way to get to there from here
  mov rax, 0
  mov [rcx + 8 * rdi], rax
  ret

.hasTransitions:

  sub rsp, 3 * 8
  ;; slots
  ;; rsp + 16, current word
  ;; rsp + 8, currTransition
  ;; rsp + 0, accumulator
  mov rax, 0
  mov [rsp + 0], rax
  mov [rsp + 16], rdi

  ; calculate sum of recursing on each possible transition
.recurseLoop:
  mov [rsp + 8], r8

  mov rdi, [r8]
  ; mov rsi, rsi
  ; mov rdx, rdx
  ; mov rcx, rcx
  call countPaths
  add [rsp + 0], rax

  mov r8, [rsp + 8]

  add r8, 8

  cmp QWORD [r8], 0
  jne .recurseLoop

  mov rdi, [rsp + 16]
  mov rax, [rsp + 0]
  mov [rcx + 8 * rdi], rax

  add rsp, 3 * 8
  ret