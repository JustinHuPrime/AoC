extern mmap, putlong, newline, exit, findc, countc, alloc

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define accumulator [rsp + 8]
%define goal r13w
%define buttons [rsp + 16]
%define todoHead r15
%define todoTail rbx
%define visited r14

;; struct TodoListEntry {
;;   currPresses: u64
;;   currLights: u16
;;   _padding: [u16; 3]
;;   next: *TodoListEntry
;; }
%define sizeofTodoListEntry 3 * 8
%define offsetofTodoListEntryCurrPresses 0
%define offsetofTodoListEntryCurrLights 8
%define offsetofTodoListEntryNext 16

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 3 * 8
  ;; slots
  ;; rsp + 16, buttons
  ;; rsp + 8, accumulator
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov rax, 0
  mov accumulator, rax
.loop:

  ; skip "["
  inc currChar

  ; parse goal
  mov goal, 0
  mov di, 1 ; rdi = toggle
.parseGoal:

  cmp BYTE [currChar], '#'
  jne .continueParseGoal

  or goal, di

.continueParseGoal:
  inc currChar
  shl di, 1

  cmp BYTE [currChar], ']'
  jne .parseGoal

  add currChar, 2 ; skip "] "

  ; count and allocate buttons (as zero-terminated array)
  mov rdi, currChar
  mov sil, '{'
  call findc

  mov rdi, currChar
  mov rsi, rax
  mov dl, '('
  call countc
  lea rdi, [rax * 2 + 2]
  call alloc
  mov buttons, rax

  mov rdi, buttons ; rdi = current button
.parseButtons:

  inc currChar
.parseButton:

  mov cl, [currChar]
  sub cl, '0'
  mov si, 1
  shl si, cl
  or [rdi], si

  ; next element of button
  add currChar, 2

  cmp BYTE [currChar], ' '
  jne .parseButton

  ; next button
  inc currChar
  add rdi, 2

  cmp BYTE [currChar], '{'
  jne .parseButtons

  ; part 2 would parse joltage here

  ; do breadth-first traversal through search space
  mov rdi, sizeofTodoListEntry
  call alloc
  mov todoHead, rax
  mov todoTail, todoHead
  mov rdi, 1 << 16
  call alloc
  mov visited, rax
.solve:
  ; handle visited accumulator
  movzx rax, WORD [todoHead + offsetofTodoListEntryCurrLights]
  cmp BYTE [visited + rax], 0
  jnz .continueSolve
  mov BYTE [visited + rax], 1

  ; check - is ths the right set of lights?
  cmp goal, ax
  je .endSolve

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

  mov ax, [todoHead + offsetofTodoListEntryCurrLights]
  xor ax, [rbp]
  mov [todoTail + offsetofTodoListEntryCurrLights], ax

  add rbp, 2

  cmp WORD [rbp], 0
  jne .addNext

.continueSolve:
  mov todoHead, [todoHead + offsetofTodoListEntryNext]

  jmp .solve
.endSolve:

  ; add presses needed to accumulator
  mov rax, [todoHead + offsetofTodoListEntryCurrPresses]
  add accumulator, rax

  mov rdi, currChar
  mov sil, `\n`
  call findc
  lea currChar, [rax + 1]

  cmp currChar, endOfFile
  jb .loop

  mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit
