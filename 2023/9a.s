extern exit, mmap, putslong, newline, findws, atosl, alloc

section .text

%define curr [rsp + 0]
%define eof [rsp + 8]
%define accumulator [rsp + 16]
%define sequenceStackPtr rbx
%define sequencePtr rbp
%define SLONG_MIN 0x8000000000000000
%define prevSequencePtr r12
%define zeroCheck [rsp + 24]

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 4 * 8
  ;; slots
  ;; rsp + 0 = curr
  ;; rsp + 8 = eof
  ;; rsp + 16 = accumulator
  ;; rsp + 24 = zeroCheck

  mov curr, rax
  add rax, rdx
  mov eof, rax
  mov QWORD accumulator, 0

  ; do-while curr < eof
.lineLoop:

  ; reset sequence stack
  mov sequenceStackPtr, sequenceStack

  ; allocate a line
  mov rdi, 256 * 8
  call alloc

  mov [sequenceStackPtr], rax
  add sequenceStackPtr, 8

  mov sequencePtr, [sequenceStackPtr - 8]

  ; read in the line
.readLineLoop:
  ; read number
  mov rdi, curr
  call findws
  mov rdi, curr
  mov rsi, rax
  mov curr, rax
  call atosl

  ; store in sequence
  mov [sequencePtr], rax
  add sequencePtr, 8

  mov rax, curr
  mov al, [rax]

  inc QWORD curr ; skip whitespace

  ; stop on newline
  cmp al, 0xa
  jne .readLineLoop

  ; terminate list with SLONG_MIN
  mov rax, SLONG_MIN
  mov [sequencePtr], rax
  add sequencePtr, 8

  ; do-while zeroCheck != 0
.calculateTrendLoop:
  ; look at the old line
  mov prevSequencePtr, [sequenceStackPtr - 8]
  add prevSequencePtr, 8

  ; allocate a new line
  mov rdi, 256 * 8
  call alloc

  mov [sequenceStackPtr], rax
  add sequenceStackPtr, 8

  mov sequencePtr, [sequenceStackPtr - 8]

  ; do-while *prevSequencePtr != SLONG_MIN
  mov QWORD zeroCheck, 0
.calculateTrendOnceLoop:

  ; *current = previous[0] - previous[-1]
  mov rax, [prevSequencePtr]
  sub rax, [prevSequencePtr - 8]
  mov [sequencePtr], rax
  add sequencePtr, 8
  or zeroCheck, rax

  add prevSequencePtr, 8

  mov rax, SLONG_MIN
  cmp QWORD [prevSequencePtr], rax
  jne .calculateTrendOnceLoop

  ; terminate list with SLONG_MIN
  mov rax, SLONG_MIN
  mov [sequencePtr], rax
  add sequencePtr, 8

  cmp QWORD zeroCheck, 0
  jne .calculateTrendLoop

  ; actually extrapolate

  mov prevSequencePtr, [sequenceStackPtr - 8]
  sub sequenceStackPtr, 8

.initExtrapolateLoopFindLast:
  add prevSequencePtr, 8

  mov rax, SLONG_MIN
  cmp [prevSequencePtr], rax
  jne .initExtrapolateLoopFindLast

  ; do-while sequence stack has elements
  ; invariant: prevSequencePtr is pointed at end of previous sequence
  ;            sequencePtr is pointed at end of sequence to extend
.extrapolateLoop:
  ; get current sequence
  mov sequencePtr, [sequenceStackPtr - 8]
  sub sequenceStackPtr, 8

  ; find last element of current sequence
  ; do-while not at end of sequence
.extrapolateLoopFindLast:
  add sequencePtr, 8

  mov rax, SLONG_MIN
  cmp [sequencePtr], rax
  jne .extrapolateLoopFindLast

  ; sequencePtr[0] = sequencePtr[-1] + prevSequencePtr[-1]
  mov rax, [sequencePtr - 8]
  add rax, [prevSequencePtr - 8]
  mov [sequencePtr], rax
  add sequencePtr, 8

  ; prevSequencePtr = sequencePtr
  mov prevSequencePtr, sequencePtr

  cmp sequenceStackPtr, sequenceStack
  jne .extrapolateLoop

  ; extract extrapolated value
  mov rax, [prevSequencePtr - 8]
  add accumulator, rax

  mov rax, curr
  cmp rax, eof
  jb .lineLoop

  mov rdi, accumulator
  call putslong
  call newline

  mov dil, 0
  call exit

section .bss
sequenceStack: resq 256
