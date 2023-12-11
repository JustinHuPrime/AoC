extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define galaxySize (2 * 8)
%define galaxyPtr rbp
%define x r12
%define y r13
%define endOfGalaxies [rsp + 0]
%define maxX [rsp + 8]
%define maxY [rsp + 16]
%define accumulator r15
%define firstGalaxyPtr rbx
%define secondGalaxyPtr rbp

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof/endOfGalaxies
  ;; rsp + 8 = maxX
  ;; rsp + 16 = maxY

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; read input
  mov y, 0
  mov galaxyPtr, galaxies
.readLinesLoop:

  mov x, 0
.readLineLoop:

  cmp BYTE [curr], '#'
  jne .continueReadLineLoop

  ; found a galaxy
  mov [galaxyPtr + 0], x
  mov [galaxyPtr + 8], y
  add galaxyPtr, galaxySize

.continueReadLineLoop:

  inc x
  inc curr

  cmp BYTE [curr], 0xa
  jne .readLineLoop

  inc y
  inc curr ; skip newline

  cmp curr, eof
  jb .readLinesLoop

  mov endOfGalaxies, galaxyPtr

  ; find maxX, maxY
  mov QWORD maxX, 0
  mov QWORD maxY, 0

  ; for each galaxy
  mov galaxyPtr, galaxies
.findMaxLoop:

  mov rax, [galaxyPtr + 0]
  cmp rax, maxX
  jng .findMaxLoopKeepX

  mov maxX, rax

.findMaxLoopKeepX:

  mov rax, [galaxyPtr + 8]
  cmp rax, maxY
  jng .findMaxLoopKeepY

  mov maxY, rax

.findMaxLoopKeepY:

  add galaxyPtr, galaxySize

  cmp galaxyPtr, endOfGalaxies
  jb .findMaxLoop

  ; expand in the x-direction
  mov x, 0
.expandXLoop:

  ; is there a galaxy with this x-value?
  mov galaxyPtr, galaxies
.checkXLoop:

  cmp x, [galaxyPtr + 0]
  je .continueExpandXLoop

  add galaxyPtr, galaxySize

  cmp galaxyPtr, endOfGalaxies
  jb .checkXLoop

  ; there isn't - for each galaxy with an x-value greater than this, increment its x-value
  mov galaxyPtr, galaxies
.doExpandXLoop:

  cmp x, [galaxyPtr + 0]
  jge .continueDoExpandXLoop

  inc QWORD [galaxyPtr + 0]

.continueDoExpandXLoop:

  add galaxyPtr, galaxySize

  cmp galaxyPtr, endOfGalaxies
  jb .doExpandXLoop

  inc x ; skip expanded column
  inc QWORD maxX

.continueExpandXLoop:
  inc x

  cmp x, maxX
  jb .expandXLoop ; note - we know there is a galaxy with the maxX value

  ; expand in the y-direction
  mov y, 0
.expandYLoop:

  ; is there a galaxy with this y-value?
  mov galaxyPtr, galaxies
.checkYLoop:

  cmp y, [galaxyPtr + 8]
  je .continueExpandYLoop

  add galaxyPtr, galaxySize

  cmp galaxyPtr, endOfGalaxies
  jb .checkYLoop

  ; there isn't - for each galaxy with an y-value greater than this, increment its y-value
  mov galaxyPtr, galaxies
.doExpandYLoop:

  cmp y, [galaxyPtr + 8]
  jge .continueDoExpandYLoop

  inc QWORD [galaxyPtr + 8]

.continueDoExpandYLoop:

  add galaxyPtr, galaxySize

  cmp galaxyPtr, endOfGalaxies
  jb .doExpandYLoop

  inc y ; skip expanded row
  inc QWORD maxY

.continueExpandYLoop:
  inc y

  cmp y, maxY
  jb .expandYLoop ; note - we know there is a galaxy with the maxY value

  ; calculate pairwise taxicab distances
  mov accumulator, 0
  mov firstGalaxyPtr, galaxies
.calculateDistancesLoop:

  ; given this galaxy, calculate distances to every following galaxy
  lea secondGalaxyPtr, [firstGalaxyPtr + galaxySize]
.calculatePairDistancesLoop:
  cmp secondGalaxyPtr, endOfGalaxies
  jnb .endCalculatePairDistancesLoop

  mov rdi, firstGalaxyPtr
  mov rsi, secondGalaxyPtr
  call taxicab
  add accumulator, rax

  add secondGalaxyPtr, galaxySize

  jmp .calculatePairDistancesLoop
.endCalculatePairDistancesLoop:

  add firstGalaxyPtr, galaxySize

  cmp firstGalaxyPtr, endOfGalaxies
  jb .calculateDistancesLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = pointer to first (x, y) pair
;; rsi = pointer to second (x, y) pair
;; clobbers rdi, rsi, xmm1, xmm2
;; returns taxicab distance between the two: |x1 - x2| + |y1 - y2|
taxicab:
  movdqu xmm1, [rdi]
  movdqu xmm2, [rsi]
  psubq xmm1, xmm2
  movdqu [rsp - 16], xmm1 ; red zone buffer

  mov rdi, [rsp - 16]
  test rdi, rdi
  jns .xNotNegative
  
  neg rdi

.xNotNegative:

  mov rsi, [rsp - 8]
  test rsi, rsi
  jns .yNotNegative

  neg rsi

.yNotNegative:

  mov rax, rdi
  add rax, rsi
  ret

section .bss
;; struct Galaxy {
;;   qword x;
;;   qword y;
;; }
galaxies: resq galaxySize * 512