extern exit, mmap, putlong, findnotnum, atol, newline

section .text

%define curr rbx
%define eof [rsp + 0]
%define accumulator [rsp + 8]
%define springPtr rbp
%define runPtr r12
%define OPERATIONAL 0b00000001
%define DAMAGED     0b00000010
%define unknownPtr r13

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
  mov unknownPtr, unknowns

  ; read the input

  ; read spring record
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

  mov BYTE [springPtr], OPERATIONAL
  mov [unknownPtr], springPtr
  inc springPtr
  add unknownPtr, 8

  inc curr

  jmp .readSprings
.readSpringsNotQuestion:

  mov BYTE [springPtr], 0
  mov QWORD [unknownPtr], 0

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

  ; zero-terminate list
  mov QWORD [runPtr], 0

  ; skip newline
  inc curr

  ; for all possibilities for damaged springs
.countPossibiltiesLoop:

  ; is this a valid possibility?
  mov rdi, springs
  mov rsi, runs
  call checkValid
  add accumulator, rax

  ; increment
  mov rdi, unknowns
  mov rsi, unknownPtr
  call increment

  test rax, rax
  jz .countPossibiltiesLoop

  cmp curr, eof
  jb .lineLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

%define currRun rax
%define runs rsi
%define springs rdi

;; rdi = springs, zero-terminated
;; rsi = runs, zero-terminated
;; clobbers rdi, rsi
;; returns whether the current arrangement is valid given the runs
checkValid:
  mov currRun, [runs]
  add runs, 8

  ; do-while currRun != 0
.checkRuns:
  
  ; skip operational springs (get to the start of the current run)
.skipInitOperational:
  test BYTE [springs], OPERATIONAL
  jz .endSkipInitOperational

  inc springs

  jmp .skipInitOperational
.endSkipInitOperational:

  ; check for currRun damaged springs in a row
.checkDamagedRun:
  test BYTE [springs], DAMAGED
  jz .endCheckDamagedRun

  dec currRun
  inc springs

  jmp .checkDamagedRun
.endCheckDamagedRun:

  ; require that we've got exactly zero
  test currRun, currRun
  jnz .false

  ; get next run
  mov currRun, [runs]
  add runs, 8

  test currRun, currRun
  jnz .checkRuns

  ; check the tail - require that springs are not damaged
.checkTail:
  cmp BYTE [springs], 0
  je .true

  test BYTE [springs], DAMAGED
  jnz .false

  inc springs

  jmp .checkTail

.false:
  mov rax, 0
  ret

.true:
  mov rax, 1
  ret

%undef springs
%undef runs
%undef currRun

%define carry al
%define currDigitPtr rdi
%define endOfDigits rsi
%define currDigit rdx

;; rdi = start of digit pointers
;; rsi = end of digit pointers
;; clobbers rdi, rsi, rdx
;; increments number, where OPERATIONAL = 0 and DAMAGED = 1
;; returns carry flag
increment:
  mov carry, 1

  ; do-while currDigitPtr != endOfDigits and carry != 0
.incrementLoop:
  mov currDigit, [currDigitPtr]

  ; if currDigit == 0
  test BYTE [currDigit], OPERATIONAL
  jz .isOne

  ; current digit is zero - set it to one, clear carry, return
  and BYTE [currDigit], ~OPERATIONAL
  or BYTE [currDigit], DAMAGED
  mov carry, 0
  ret

.isOne:

  ; current digit is one - set it to zero, continue
  and BYTE [currDigit], ~DAMAGED
  or BYTE [currDigit], OPERATIONAL

  add currDigitPtr, 8

  cmp currDigitPtr, endOfDigits
  jb .incrementLoop

  ret

%undef currDigit
%undef endOfDigits
%undef currDigitPtr
%undef carry

section .bss
springs: resb 32
unknowns: resq 32
runs: resq 16
