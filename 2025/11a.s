extern mmap, putlong, newline, exit, alloc, findc, countc

section .text

%define currChar r12
%define endOfFile [rsp + 0]
%define transitions r13
%define you (('y' - 'a') * 26 * 26 + ('o' - 'a') * 26 + ('u' - 'a'))
%define out (('o' - 'a') * 26 * 26 + ('u' - 'a') * 26 + ('t' - 'a'))
%define accumulator [rsp + 8]
%define todo r14

;; struct Todo {
;;   location: u64
;;   next: *Todo
;; }
%define sizeofTodo (2 * 8)
%define offsetofTodoLocation 0
%define offsetofTodoNext 8

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 8, accumulator
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

  mov rax, 0
  mov accumulator, rax

  mov rdi, sizeofTodo
  call alloc
  mov todo, rax
  mov rax, you
  mov [todo + offsetofTodoLocation], rax
.searchLoop:
  mov rax, [todo + offsetofTodoLocation]

  ; check - are we at the exit
  cmp rax, out
  jne .notAtExit

  inc QWORD accumulator
  mov todo, [todo + offsetofTodoNext]
  jmp .continueSearch

.notAtExit:

  ; discard current
  mov todo, [todo + offsetofTodoNext]

  ; add next possible elements
  mov rbx, [transitions + 8 * rax]
.addNext:

  mov rdi, sizeofTodo
  call alloc
  mov rdi, [rbx]
  mov [rax + offsetofTodoLocation], rdi
  mov [rax + offsetofTodoNext], todo
  mov todo, rax

  add rbx, 8

  cmp QWORD [rbx], 0
  jne .addNext

.continueSearch:

  test todo, todo
  jnz .searchLoop

  mov rdi, accumulator
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
