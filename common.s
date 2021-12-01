section .text

;; rdi = start of string
;; rsi = end of string
;; returns integer value of string
;; clobbers rdi, rdx, rcx
global atol:function
atol:
  mov rax, 0 ; buffer = 0
  mov rdx, 10

  ; while current < end
.loop:
  cmp rdi, rsi
  jge .end

  imul rax, rdx ; rax *= 10

  mov cl, [rdi] ; rax += *current - '0'
  sub cl, '0'
  movzx rcx, cl
  add rax, rcx

  inc rdi ; ++current

  jmp .loop
.end:

  ret

;; writeNewline:
;; clobbers rax, rdi, rsi, rdx
global writeNewline:function
writeNewline:
  mov BYTE [writeBuf], 0xa

  mov rax, 1
  mov rdi, 1
  mov rsi, writeBuf
  mov rdx, 1
  syscall

  ret

;; rdi = unsigned long to write
;; clobbers rax, rdi, rsi, rdx
global writeLong:function
writeLong:
  ; special case: rdi = 0
  cmp rdi, 0
  jne .continue

  mov BYTE [writeBuf], '0'

  mov rax, 1
  mov rdi, 1
  mov rsi, writeBuf
  mov rdx, 1
  syscall

  ret

.continue:

  mov rax, rdi ; rax = number to write
  mov rdi, writeBufEnd ; rdi = start of string
  mov rsi, 10

  ; while rax != 0
.loop:
  test rax, rax
  jz .end

  dec rdi
  
  mov rdx, 0
  div rsi

  ; *rdi = (rax % 10) + '0'
  add dl, '0'
  mov [rdi], dl

  jmp .loop
.end:

  mov rax, 1 ; write buffer
  mov rsi, rdi
  mov rdi, 1
  mov rdx, writeBufEnd
  sub rdx, rsi
  syscall
  
  ret

;; rdi = start of string
;; returns pointer to newline
;; doesn't clobber
global findNewline:function
findNewline:
  mov rax, rdi

  ; while *rax != '\n'
.loop:
  cmp BYTE [rax], 0xa
  je .end

  inc rax ; ++rax
  
  jmp .loop
.end:

  ret

;; rdi = length to allocate
;; returns pointer to allocation
;; clobbers rsi, rdi
global alloc:function
alloc:
  mov rsi, rdi

  ; if old brk is not zero, skip getting it
  cmp QWORD [oldBrk], 0
  jne .haveBrk

  mov rax, 12
  mov rdi, 0
  syscall
  
  jmp .gotBrk
.haveBrk:

  mov rax, [oldBrk]

.gotBrk:

  ; actually allocate
  lea rdi, [rax + rsi] ; rdi = new brk
  mov rsi, rax ; rsi = old brk
  mov rax, 12
  syscall

  mov [oldBrk], rax ; save new brk

  mov rax, rsi ; return rsi
  ret

section .data
oldBrk:
  dq 0

section .bss

writeBuf:
  resb 20
writeBufEnd: