extern exit, mmap, putlong, findnotnum, atol, newline

section .text

%define curr rbx
%define eof [rsp + 0]
%define accumulator [rsp + 8]
%define springPtr rbp
%define runPtr r12
%define OPERATIONAL 0b00000001
%define DAMAGED     0b00000010
%define mainSequenceEndPtr r13
%define mainSequencePtr r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0 = eof
  ;; rsp + 8 = accumulator

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; for each line
  mov QWORD accumulator, 0
.lineLoop:
  ; reset pointers
  mov springPtr, springs
  mov runPtr, runs

  ; clear memoization
  mov rdi, memoization
  mov rax, -1
  mov rcx, 128 * 64 * 32
  rep stosq

  ; read the input

  ; read spring record, with leading '.'
  mov BYTE [springPtr], OPERATIONAL
  inc springPtr
.readSprings:

  mov al, [curr]

  cmp al, '.'
  jne .readSpringsNotDot

  mov BYTE [springPtr], OPERATIONAL
  inc springPtr

  inc curr

  jmp .readSprings
.readSpringsNotDot:

  cmp al, '#'
  jne .readSpringsNotHash

  mov BYTE [springPtr], DAMAGED
  inc springPtr

  inc curr

  jmp .readSprings
.readSpringsNotHash:

  cmp al, '?'
  jne .readSpringsNotQuestion

  mov BYTE [springPtr], OPERATIONAL | DAMAGED
  inc springPtr

  inc curr

  jmp .readSprings
.readSpringsNotQuestion:

  ; expand springs

  mov mainSequenceEndPtr, springPtr
  mov rcx, 4
.expandSprings:
  mov mainSequencePtr, springs + 1

  ; append a '?'
  mov BYTE [springPtr], OPERATIONAL | DAMAGED
  inc springPtr
  
  ; do-while mainSequencePtr != mainSequenceEndPtr
.expandSpringsOnce:
  mov al, [mainSequencePtr]
  mov [springPtr], al
  inc springPtr
  inc mainSequencePtr

  cmp mainSequencePtr, mainSequenceEndPtr
  jb .expandSpringsOnce

  loop .expandSprings

  ; zero-terminate list
  mov BYTE [springPtr], 0

  ; read runs
.readRuns:
  inc curr ; skip leading character

  mov rdi, curr
  call findnotnum
  mov rdi, curr
  mov rsi, rax
  mov curr, rax
  call atol

  ; store run
  mov [runPtr], rax
  add runPtr, 8

  cmp BYTE [curr], `\n`
  jne .readRuns

  ; expand runs
  mov mainSequenceEndPtr, runPtr
  mov rcx, 4
.expandRuns:
  mov mainSequencePtr, runs

  ; do-while mainSequencePtr != mainSequenceEndPtr
.expandRunsOnce:
  mov rax, [mainSequencePtr]
  mov [runPtr], rax
  add runPtr, 8
  add mainSequencePtr, 8

  cmp mainSequencePtr, mainSequenceEndPtr
  jb .expandRunsOnce

  loop .expandRuns

  ; zero-terminate list
  mov QWORD [runPtr], 0

  ; skip newline
  inc curr

  mov rdi, 0
  mov rsi, 0
  mov rdx, 0
  call solutions
  add accumulator, rax

  cmp curr, eof
  jb .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

%define spring rdi
%define run rsi
%define currentRun rdx
%define thisSpring [rsp + 0]
%define thisRun [rsp + 8]
%define thisCurrentRun [rsp + 16]

; solutions(spring, run, currentRun) =
;   if &springs[spring] == springPtr && &runs[run] == runPtr && currentRun == 0
;      return 1
;   elseif currentRun == 0
;     switch springs[spring]
;       case OPERATIONAL: solutions(spring + 1, run, 0) + solutions(spring + 1, run + 1, runs[run])
;       case DAMAGED: 0
;   else
;     switch springs[spring]
;       case OPERATIONAL: 0
;       case DAMAGED: solutions(spring + 1, run, currentRun - 1)

;; rdi = spring index
;; rsi = run index
;; rdx = length of current run
;; uses springs
;; uses runs
;; uses memoization
;; uses springPtr
;; uses runPtr
;; clobbers
;; returns number of solutions for the given current spring and next run and current run left (-1 = not started)
solutions:
  ; memoization check
  mov r8, spring
  shl r8, 11
  mov r9, run
  shl r9, 5
  mov rax, currentRun
  add rax, r9
  add rax, r8
  cmp QWORD [memoization + rax * 8], -1
  jne .memoized

  ; termination check
  lea rax, [springs + spring]
  cmp rax, springPtr
  jne .continue

  lea rax, [runs + run * 8]
  cmp rax, runPtr
  jne .continue

  test currentRun, currentRun
  jnz .continue

  jmp .unmemoizedOne

.continue:

  sub rsp, 3 * 8
  ;; slots
  ;; rsp + 0 = thisSpring
  ;; rsp + 8 = thisRun
  ;; rsp + 16 = thisCurrentRun
  mov thisSpring, spring
  mov thisRun, run
  mov thisCurrentRun, currentRun

  test currentRun, currentRun
  jnz .notZero

  ; currentRun == 0
  ;   switch springs[spring]
  ;     case OPERATIONAL: solutions(spring + 1, run, 0) + solutions(spring + 1, run + 1, runs[run])
  ;     case DAMAGED: 0

  test BYTE [springs + spring], OPERATIONAL
  jz .overrun

  inc spring
  mov currentRun, 0
  call solutions
  mov run, thisRun
  mov spring, thisSpring
  inc spring
  mov currentRun, [runs + run * 8]
  inc run
  push rax
  call solutions
  pop rdi
  add rax, rdi
  jmp .unmemoized

.overrun:
  mov rax, 0
  jmp .unmemoizedZero

.notZero:

  ; currentRun != 0
  ;   switch springs[spring]
  ;     case OPERATIONAL: 0
  ;     case DAMAGED: solutions(spring + 1, run, currentRun - 1)

  test BYTE [springs + spring], DAMAGED
  jz .underrun

  inc spring
  dec currentRun
  call solutions
  jmp .unmemoized

.underrun:
  mov rax, 0
  jmp .unmemoizedZero

.unmemoized:
  mov spring, thisSpring
  mov run, thisRun
  mov currentRun, thisCurrentRun

.unmemoizedZero:
  add rsp, 3 * 8
  shl spring, 11
  shl run, 5
  add currentRun, spring
  add currentRun, run
  mov [memoization + currentRun * 8], rax
  ret

.unmemoizedOne:
  mov rax, 1
  shl spring, 11
  shl run, 5
  add currentRun, spring
  add currentRun, run
  mov [memoization + currentRun * 8], rax
  ret

.memoized:
  mov rax, [memoization + rax * 8]
  ret

%undef spring
%undef run
%undef currentRun
%undef thisSpring
%undef thisRun
%undef thisCurrentRun

section .bss
springs: resb 128
runs: resq 64
memoization: resq 128 * 64 * 32