extern exit, mmap, putlong, newline, alloc, findws, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define currLine r13
%define currCol r14

%define curr r12
%define todoHead r13
%define accumulator r15
%define currType r14b
%define sides rbp
%define area rbx

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  ; read file
  mov currLine, map + 256 + 1
.readLoop:

  mov currCol, currLine
.readLineLoop:

  mov al, [currChar]
  mov [currCol], al

  inc currChar
  inc currCol

  cmp BYTE [currChar], `\n`
  jne .readLineLoop

  inc currChar
  add currLine, 256

  cmp currChar, endOfFile
  jb .readLoop

  ; for each cell
  mov curr, 256 + 1
  mov accumulator, 0
.scanLoop:

  cmp BYTE [map + curr], 0 ; not valid cell
  je .continueScanLoop
  cmp QWORD [visited + 8 * curr], 0 ; visited
  jne .continueScanLoop

  ; valid cell that's not visited - do flood fill
  ;; while-loop-tail-recursive graph traversal with todo list, visited, and rsf accumulator
  mov todoHead, todo
  mov [todoHead], curr
  add todoHead, 8

  mov currType, [map + curr]
  
  mov area, 0
.traverseAreaLoop:
  sub todoHead, 8
  mov rax, [todoHead]

  ; if already visited, skip
  cmp QWORD [visited + 8 * rax], 0
  jne .continueTraverseAreaLoop

  ; mark as visited
  mov [visited + 8 * rax], curr
  ; add to area
  inc area

  ; check each neighbour
  cmp [map + rax - 256], currType
  jne .doneUp
  cmp QWORD [visited + 8 * (rax - 256)], 0
  jne .doneUp

  lea rdx, [rax - 256]
  mov [todoHead], rdx
  add todoHead, 8

.doneUp:
  cmp [map + rax + 256], currType
  jne .doneDown
  cmp QWORD [visited + 8 * (rax + 256)], 0
  jne .doneDown

  lea rdx, [rax + 256]
  mov [todoHead], rdx
  add todoHead, 8

.doneDown:
  cmp [map + rax - 1], currType
  jne .doneLeft
  cmp QWORD [visited + 8 * (rax - 1)], 0
  jne .doneLeft

  lea rdx, [rax - 1]
  mov [todoHead], rdx
  add todoHead, 8

.doneLeft:
  cmp [map + rax + 1], currType
  jne .doneRight
  cmp QWORD [visited + 8 * (rax + 1)], 0
  jne .doneRight

  lea rdx, [rax + 1]
  mov [todoHead], rdx
  add todoHead, 8

.doneRight:
.continueTraverseAreaLoop:

  cmp todoHead, todo
  ja .traverseAreaLoop

  ; count sides
  mov sides, 0

  ; count up-facing sides
  mov currLine, 256 + 1
.countUpLoop:

  mov rax, 0 ; rax = were we on an edge right now
  mov currCol, currLine
.countUpElementLoop:

  test rax, rax
  jz .notOnUpEdge

  ; are we on an edge now?
  cmp [visited + 8 * currCol], curr
  jne .leavingUpEdge
  cmp [visited + 8 * (currCol - 256)], curr
  je .leavingUpEdge
  jmp .continueCountUpElementLoop

.leavingUpEdge:

  ; nope, left the edge
  inc sides
  mov rax, 0

  jmp .continueCountUpElementLoop
.notOnUpEdge:

  ; are we on an edge now?
  cmp [visited + 8 * currCol], curr
  jne .continueCountUpElementLoop
  cmp [visited + 8 * (currCol - 256)], curr
  je .continueCountUpElementLoop
  
  ; yes! record that fact
  mov rax, 1

.continueCountUpElementLoop:
  inc currCol

  cmp BYTE [map + currCol], 0
  jne .countUpElementLoop

  add sides, rax

  add currLine, 256

  cmp BYTE [map + currLine], 0
  jne .countUpLoop

  ; count down-facing sides
  mov currLine, 256 + 1
.countDownLoop:

  mov rax, 0 ; rax = were we on an edge right now
  mov currCol, currLine
.countDownElementLoop:

  test rax, rax
  jz .notOnDownEdge

  ; are we on an edge now?
  cmp [visited + 8 * currCol], curr
  jne .leavingDownEdge
  cmp [visited + 8 * (currCol + 256)], curr
  je .leavingDownEdge
  jmp .continueCountDownElementLoop

.leavingDownEdge:

  ; nope, left the edge
  inc sides
  mov rax, 0

  jmp .continueCountDownElementLoop
.notOnDownEdge:

  ; are we on an edge now?
  cmp [visited + 8 * currCol], curr
  jne .continueCountDownElementLoop
  cmp [visited + 8 * (currCol + 256)], curr
  je .continueCountDownElementLoop
  
  ; yes! record that fact
  mov rax, 1

.continueCountDownElementLoop:
  inc currCol

  cmp BYTE [map + currCol], 0
  jne .countDownElementLoop

  add sides, rax

  add currLine, 256

  cmp BYTE [map + currLine], 0
  jne .countDownLoop

  ; count left-facing sides
  mov currCol, 256 + 1
.countLeftLoop:

  mov rax, 0 ; rax = were we on an edge right now
  mov currLine, currCol
.countLeftElementLoop:

  test rax, rax
  jz .notOnLeftEdge

  ; are we on an edge now?
  cmp [visited + 8 * currLine], curr
  jne .leavingLeftEdge
  cmp [visited + 8 * (currLine - 1)], curr
  je .leavingLeftEdge
  jmp .continueCountLeftElementLoop

.leavingLeftEdge:

  ; nope, left the edge
  inc sides
  mov rax, 0

  jmp .continueCountLeftElementLoop
.notOnLeftEdge:

  ; are we on an edge now?
  cmp [visited + 8 * currLine], curr
  jne .continueCountLeftElementLoop
  cmp [visited + 8 * (currLine - 1)], curr
  je .continueCountLeftElementLoop
  
  ; yes! record that fact
  mov rax, 1

.continueCountLeftElementLoop:
  add currLine, 256

  cmp BYTE [map + currLine], 0
  jne .countLeftElementLoop

  add sides, rax

  inc currCol

  cmp BYTE [map + currCol], 0
  jne .countLeftLoop

  ; count right-facing sides
  mov currCol, 256 + 1
.countRightLoop:

  mov rax, 0 ; rax = were we on an edge right now
  mov currLine, currCol
.countRightElementLoop:

  test rax, rax
  jz .notOnRightEdge

  ; are we on an edge now?
  cmp [visited + 8 * currLine], curr
  jne .leavingRightEdge
  cmp [visited + 8 * (currLine + 1)], curr
  je .leavingRightEdge
  jmp .continueCountRightElementLoop

.leavingRightEdge:

  ; nope, left the edge
  inc sides
  mov rax, 0

  jmp .continueCountRightElementLoop
.notOnRightEdge:

  ; are we on an edge now?
  cmp [visited + 8 * currLine], curr
  jne .continueCountRightElementLoop
  cmp [visited + 8 * (currLine + 1)], curr
  je .continueCountRightElementLoop
  
  ; yes! record that fact
  mov rax, 1

.continueCountRightElementLoop:
  add currLine, 256

  cmp BYTE [map + currLine], 0
  jne .countRightElementLoop

  add sides, rax

  inc currCol

  cmp BYTE [map + currCol], 0
  jne .countRightLoop

  ; accumulator += area * sides
  mov rax, area
  mul sides
  add accumulator, rax

  ; mov rdi, rax
  ; call putlong
  ; call newline
  ; mov rdi, area
  ; call putlong
  ; call newline
  ; mov rdi, sides
  ; call putlong
  ; call newline
  ; call newline

.continueScanLoop:

  inc curr

  cmp curr, 256 * 256
  jb .scanLoop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

section .bss

map: resb 256 * 256
visited: resq 256 * 256
todo: resq 256 * 256
