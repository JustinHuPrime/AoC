extern mmap, putlong, newline, exit, findc, countc, alloc, findnotnum, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define accumulator [rsp + 8]
%define goal ymm0
%define buttons [rsp + 16]
%define todoHead r15
%define todoTail rbx

;; struct TodoListEntry {
;;   currPresses: u64
;;   currLevels: [u16; 16]
;;   next: *TodoListEntry
;; }
%define sizeofTodoListEntry (2 * 8 + 32)
%define offsetofTodoListEntryCurrPresses 0
%define offsetofTodoListEntryCurrLevels 8
%define offsetofTodoListEntryNext (1 * 8 + 32)

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 3 * 8 + 32
  ;; slots
  ;; rsp + 24, buffer
  ;; rsp + 16, buttons
  ;; rsp + 8, accumulator
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov rax, 0
  mov accumulator, rax
.loop:

  ; skip lights
  mov rdi, currChar
  mov sil, '('
  call findc
  mov currChar, rax

  ; count and allocate buttons (as zero-terminated array)
  mov rdi, currChar
  mov sil, '{'
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov dl, '('
  call countc
  mov rdi, rax
  inc rdi
  shl rdi, 5
  call alloc
  mov buttons, rax

  mov rdi, buttons ; rdi = current button
.parseButtons:

  inc currChar
.parseButton:

  movzx rcx, BYTE [currChar]
  sub rcx, '0'
  mov al, 1
  mov [rdi + 2 * rcx], al

  ; next element of button
  add currChar, 2

  cmp BYTE [currChar], ' '
  jne .parseButton

  ; next button
  inc currChar
  add rdi, 1 << 5

  cmp BYTE [currChar], '{'
  jne .parseButtons

  inc currChar

  mov r13, 0
  vxorps goal, goal
  vmovdqu [rsp + 24], goal
.parseGoal:

  mov rdi, currChar
  call findnotnum
  mov rdi, currChar
  mov rsi, rax
  lea currChar, [rax + 1]
  call atol
  mov [rsp + 24 + r13 * 2], ax

  inc r13

  cmp BYTE [currChar], `\n`
  jne .parseGoal

  vmovdqu goal, [rsp + 24]

  ; do breadth-first traversal through search space
.breakpoint:
  mov rdi, sizeofTodoListEntry
  call alloc
  mov todoHead, rax
  mov todoTail, todoHead
.solve:
  ; ymm1 = current levels
  vmovdqu ymm1, [todoHead + offsetofTodoListEntryCurrLevels]

  ; check - is ths the right set of joltages
  vxorps ymm2, ymm1, goal
  vptest ymm2, ymm2
  jz .endSolve

  ; add next states onto todo tail
  mov rbp, buttons
.addNext:

  mov rdi, sizeofTodoListEntry
  call alloc
  mov [todoTail + offsetofTodoListEntryNext], rax
  mov todoTail, rax

  mov rax, [todoHead + offsetofTodoListEntryCurrPresses]
  inc rax
  mov [todoTail + offsetofTodoListEntryCurrPresses], rax

  vpaddw ymm2, ymm1, [rbp]
  vmovdqu [todoTail + offsetofTodoListEntryCurrLevels], ymm2

  add rbp, 1 << 5

  vmovdqu ymm2, [rbp]
  vptest ymm2, ymm2
  jnz .addNext

.continueSolve:
  mov todoHead, [todoHead + offsetofTodoListEntryNext]

  jmp .solve
.endSolve:

  ; add presses needed to accumulator
  mov rax, [todoHead + offsetofTodoListEntryCurrPresses]
  add accumulator, rax

  inc currChar

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit
