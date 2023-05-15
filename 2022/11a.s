extern mmap, exit, putlong, countc, alloc, findnl, atol

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  mov rdi, r15
  mov rsi, r14
  mov dl, ','
  call countc
  mov r13, rax ; r13 = total number of items
  mov rdi, r15
  mov rsi, r14
  mov dl, ':'
  call countc
  add r13, rax
  mov rbx, rax ; rbx = count of monkeys

  mov rdi, rax
  shl rdi, 6
  call alloc
  mov rbp, rax ; rbp = monkey array
  
  ; read input
  ; r12 = current monkey array offset
  mov r12, 0
.inputLoop:
  cmp r15, r14
  jnl .endInputLoop

  ; allocate items array
  mov rdi, r13
  call alloc
  mov [rbp + r12 + 0], rax ; store items array pointer
  mov r11, rax ; r11 = items array pointer

  ; read items array
  add r15, 28 ; skip "Monkey 0:", newline, "  Starting items: "
  mov r10, 0 ; r10 = current item array index
.inputItemLoop:
  mov rdi, r15
  lea rsi, [r15 + 2]
  call atol
  mov [r11 + r10 * 8], rax ; store item

  inc r10

  mov al, [r15 + 2]
  add r15, 4 ; skip number, ", " (or number, newline, " ")
  cmp al, ','
  je .inputItemLoop

  mov [rbp + r12 + 8], r10 ; store count of items

  ; read operation
  add r15, 22 ; skip " Operation: new = old "

  cmp BYTE [r15 + 2], 'o'
  jne .notSquare

  ; new = old * old

  mov QWORD [rbp + r12 + 8], 2
  add r15, 27 ; skip "* old", newline "  Test: divisible by "

  jmp .doneOperation
.notSquare:

  cmp BYTE [r15], '*'
  jne .notTimes

  ; new = old * <const>

  mov QWORD [rbp + r12 + 16], 1

  jmp .getConst
.notTimes:

  ; new = old + <const>

  mov QWORD [rbp + r12 + 16], 0

.getConst:
  lea rdi, [r15 + 2]
  lea rsi, [r15 + 3]
  call atol
  mov [rbp + r12 + 24], rax

  add r15, 25 ; skip "+ ?" or "* ?", newline, "  Test: divisble by "

.doneOperation:

  ; read test number
  mov rdi, r15
  call findnl
  mov rdi, r15
  mov rsi, rax
  lea r15, [rax + 30] ; skip newline, "    If true: throw to monkey "
  call atol
  mov [rbp + r12 + 32], rax

  ; read true target
  mov rdi, r15
  lea rsi, [r15 + 1]
  call atol
  mov [rbp + r12 + 40], rax
  add r15, 32 ; skip "?", newline, "    If false: throw to monkey "

  ; read false target
  mov rdi, r15
  lea rsi, [r15 + 1]
  call atol
  mov [rbp + r12 + 48], rax
  add r15, 3 ; skip "?", newline, newline

  ; set inspection count
  mov QWORD [rbp + r12 + 56], 0

  add r12, 48

  jmp .inputLoop
.endInputLoop:

  ; currently in use:
  ; rbp = monkey array
  ; rbx = count of monkeys
  mov rdi, 0 ; rdi = current iteration
.roundLoop:
  cmp rdi, 20
  jnl .endRoundLoop

  inc rdi

  jmp .roundLoop
.endRoundLoop:

  mov dil, 0
  call exit

;; enum operation : ulong {
;;   ADD = 0
;;   MUL = 1
;;   SQU = 2
;; }
;; struct monkey {
;;   ulong *items; ; +0
;;   ulong lastIndex; +8
;;   enum operation op; ; +16
;;   ulong operand; // zero if op == SQU ; +24
;;   ulong testFactor; ; +32
;;   ulong trueTarget; ; +40
;;   ulong falseTarget; ; +48
;;   ulong inspectionCount; ; +56
;; }
;; sizeof(struct monkey) == 64