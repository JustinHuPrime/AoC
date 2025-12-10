extern mmap, putlong, newline, exit, findc, countc, alloc, findnotnum, atol

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define accumulator [rsp + 8]
%define goal ymm0
%define buttons [rsp + 16]
%define children r15
%define currChild rbx
%define todoHead r15
%define todoTail rbx

%define numCores 24

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

  mov rax, 9 ; mmap
  mov rdi, 0 ; allocate a new address
  mov rsi, 0x1000 ; 1 page
  mov rdx, 3 ; prot = PROT_READ | PROT_WRITE
  mov r10, 33 ; flags = MAP_SHARED | MAP_ANONYMOUS
  mov r8, -1 ; no file backing
  mov r9, 0 ; no offset
  syscall
  mov accumulator, rax

  ; allocate children array
  mov rdi, numCores
  shl rdi, 3
  call alloc
  mov children, rax

  mov currChild, 0
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

  mov rax, 57 ; fork
  syscall
  test rax, rax
  jz solve ; if this is the child, go solve
  mov [children + 8 * currChild], rax ; if not, record the child

  inc currChild

  cmp currChild, numCores
  jb .noWait

  ; wait for all numCores children
  mov currChild, 0
.waitLoop:

  mov rax, 61 ; wait4
  mov rdi, [children + 8 * currChild] ; the child
  mov rsi, 0 ; no stats
  mov rdx, 0 ; default options
  mov r10, 0 ; no resource usage
  syscall

  inc currChild

  cmp currChild, numCores
  jb .waitLoop

  ; clear children
  mov currChild, 0
  mov rdi, children
  mov rcx, numCores
  mov rax, 0
  rep stosq

.noWait:
  inc currChar

  cmp currChar, endOfFile
  jb .loop

  ; wait for all remaining children
  mov currChild, 0
.finalWaitLoop:

  mov rax, 61 ; wait4
  mov rdi, [children + 8 * currChild] ; the child
  mov rsi, 0 ; no stats
  mov rdx, 0 ; default options
  mov r10, 0 ; no resource usage
  syscall

  inc currChild

  cmp QWORD [children + 8 * currChild], 0
  jnz .finalWaitLoop

  mov rdi, accumulator
  mov rdi, [rdi]
  call putlong
  call newline

  mov dil, 0
  call exit

solve:
  ; do breadth-first traversal through search space
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
  mov rdi, accumulator
  lock add [rdi], rax

  mov dil, 0
  call exit
