extern exit, mmap, putlong, newline, findws, atol, skipws

section .text

%use fp
%define curr r12
%define arryPtr r13
%define accumulator r13

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ;; sub rsp, 0 * 8
  ;; slots

  mov curr, rax

  ; parse input

  ; skip "Time:"
  add curr, 5
  
  ; do-while *curr != '\n'
  mov arryPtr, lengths
.readLengthsLoop:

  ; skip whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  ; read number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol

  mov [arryPtr], rax
  add arryPtr, 8

  cmp BYTE [curr], 0xa
  jne .readLengthsLoop

  ; skip "\nDistance:"
  add curr, 10

  ; do-while *curr != '\n'
  mov arryPtr, distances
.readDistancesLoop:

  ; skip whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  ; read number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol

  mov [arryPtr], rax
  add arryPtr, 8

  cmp BYTE [curr], 0xa
  jne .readDistancesLoop

  ; for each set of time, distance
  mov accumulator, 1
  mov curr, 0
  movsd xmm2, [two] ; xmm2 = 2
  movsd xmm4, [four] ; xmm4 = 4
.countCombinationsLoop:

  ; let t = time button was held for
  ; let l = length of race (time)
  ; let d(t, l) = distance travelled given button was held
  ; d(t, l) = t(l - t) = -t^2 + tl
  ; solve for -t^2 + tl > r
  ; = -t^2 + tl - r > 0
  ; -t^2 + tl - r == 0 when
  ; t = (-l +- sqrt[l^2 - 4(-1)(-r)]) / 2(-1)
  ; t = (-l +- sqrt[l^2 - 4r]) / -2
  ; t = (l +- sqrt[l^2 - 4r]) / 2
  ; t = (l/2 +- sqrt[l^2 - r]/2)
  ; t will always be in range [0, l]
  ; let t1 be the smaller solution and t2 be the larger solution
  ; calculate floor(t2 - epsilon) - ceil(t1 + epsilon) + 1

  cvtsi2sd xmm0, [lengths + curr * 8] ; xmm0 = l
  cvtsi2sd xmm1, [distances + curr * 8] ; xmm1 = r

  ; calculate 4r
  mulsd xmm1, xmm4

  ; calculate sqrt[l^2 - 4r]/2
  movsd xmm3, xmm0
  mulsd xmm3, xmm3
  subsd xmm3, xmm1
  sqrtsd xmm3, xmm3
  divsd xmm3, xmm2

  ; calculate l/2
  divsd xmm0, xmm2

  ; calculate smaller solution: ceil[l/2 - sqrt[l^2 - 4r]/2 + epsilon]
  movsd xmm1, xmm0
  subsd xmm1, xmm3
  roundsd xmm5, xmm1, 0b00000010
  cvtsd2si rax, xmm5
  comisd xmm5, xmm1
  jne .noIncrementFirst

  inc rax

.noIncrementFirst:

  ; calculate larger solution: floor[l/2 + sqrt[l^2 - 4r]/2 - epsilon]
  addsd xmm0, xmm3
  roundsd xmm5, xmm0, 0b00000001
  cvtsd2si rsi, xmm5
  comisd xmm5, xmm0
  jne .noDecrmementSecond

  dec rsi

.noDecrmementSecond:

  ; calculate floor(t2 - epsilon) - ceil(t1 + epsilon) + 1
  sub rsi, rax
  inc rsi

  ; accumulate
  imul accumulator, rsi

  inc curr

  cmp QWORD [lengths + curr * 8], 0
  jne .countCombinationsLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .rodata
two:
  dq float64(2.0)
four:
  dq float64(4.0)

section .bss
lengths: resq 5
distances: resq 5
