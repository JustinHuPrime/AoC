extern mmap, exit, putlong, newline, putc

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of file

  mov r14, r15 ; r14 = current character

  ; while next four characters aren't the same
.loop:
  ; compare first vs rest
  mov r13b, [r14]
  cmp r13b, [r14 + 1]
  je .continue
  cmp r13b, [r14 + 2]
  je .continue
  cmp r13b, [r14 + 3]
  je .continue

  ; compare second vs rest
  mov r13b, [r14 + 1]
  cmp r13b, [r14 + 2]
  je .continue
  cmp r13b, [r14 + 3]
  je .continue
  
  ; compare third vs rest
  mov r13b, [r14 + 2]
  cmp r13b, [r14 + 3]
  je .continue

  jmp .endLoop

.continue:

  inc r14

  jmp .loop
.endLoop:

  lea rdi, [r14 + 4]
  sub rdi, r15
  call putlong
  call newline

  mov dil, 0
  call exit