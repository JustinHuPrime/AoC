extern mmap, exit, putlong, newline, putc

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of file

  mov r14, r15 ; r14 = current character

  sub rsp, 26 ; [rsp + char - 'a'] = count of characters seen

  ; while next 14 characters aren't the same
.readLoop:
  ; clear count
  mov rcx, 26
  mov rdi, rsp
  mov al, 0
  rep stosb

  ; read the next 14 characters into the count
  mov rcx, 14
.readSectionLoop:

  movzx r13, BYTE [r14 + rcx - 1]
  inc BYTE [rsp + r13 - 'a']

  loop .readSectionLoop

  ; increment all seen zero times to being seen once
  mov rcx, 26
.flattenSectionLoop:

  mov r13b, [rsp + rcx - 1]
  test r13b, r13b
  jnz .continueFlattenSectionLoop

  inc BYTE [rsp + rcx - 1]

.continueFlattenSectionLoop:
  loop .flattenSectionLoop

  mov rcx, 26
  mov rdi, rsp
  mov al, 1
  repe scasb
  je .endReadLoop

  inc r14

  jmp .readLoop
.endReadLoop:

  lea rdi, [r14 + 14]
  sub rdi, r15
  call putlong
  call newline

  mov dil, 0
  call exit