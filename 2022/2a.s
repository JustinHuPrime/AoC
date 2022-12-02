extern mmap, exit, putlong, newline

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  mov r12, rax ; r12 = current character
  lea r13, [rax + rdx] ; r13 = end of file

  mov rdi, 0 ; rdi = current score
  xor eax, eax ; zero out rax, rdx - used for table lookups
  xor edx, edx
  xor esi, esi ; zero out rsi - used as value of table lookup

  ; do while r12 < r13
.loop:
  ; read characters
  mov al, [r12 + 0]
  mov dl, [r12 + 2]
  ; offset characters
  sub al, 'A'
  sub dl, 'X'

  ; lookup from table
  mov sil, [table + rax * 4 + rdx]
  
  add rdi, rsi

  add r12, 4

  cmp r12, r13
  jl .loop

  call putlong
  call newline

  mov dil, 0
  call exit

section .rodata
table:
  db 1 + 3 ; A X
  db 2 + 6 ; A Y
  db 3 + 0 ; A Z
  db 0 ; padding
  db 1 + 0 ; B X
  db 2 + 3 ; B Y
  db 3 + 6 ; B Z
  db 0 ; B ?
  db 1 + 6 ; C X
  db 2 + 0 ; C Y
  db 3 + 3 ; C Z