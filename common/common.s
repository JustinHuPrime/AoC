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

;; rdi = start of string
;; rsi = end of string
;; returns integer value of string
;; clobbers rdi, rdx
global atolBinary:function
atolBinary:
  mov rax, 0 ; buffer = 0

  ; while current < end
.loop:
  cmp rdi, rsi
  jge .end

  shl rax, 1 ; rax *= 2

  mov dl, [rdi] ; rax += *current - '0'
  sub dl, '0'
  movzx rdx, dl
  add rax, rdx

  inc rdi ; ++current

  jmp .loop
.end:

  ret

;; writeNewline:
;; clobbers rax, rdi, rsi, rdx, r11, rcx
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
;; clobbers rax, rdi, rsi, rdx, r11, rcx
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

;; rdi = start of string
;; returns pointer to character
;; doesn't clobber
global findComma:function
findComma:
  mov rax, rdi

  ; while *rax != ','
.loop:
  cmp BYTE [rax], ','
  je .end

  inc rax ; ++rax
  
  jmp .loop
.end:

  ret

;; rdi = start of string
;; returns pointer to character
;; doesn't clobber
global findWs:function
findWs:
  mov rax, rdi

  ; while *rax != ' ' && *rax != '\n'
.loop:
  cmp BYTE [rax], ' '
  je .end
  cmp BYTE [rax], 0xa
  je .end

  inc rax ; ++rax
  
  jmp .loop
.end:

  ret

;; rdi = current position in string
;; returns pointer to character
;; doesn't clobber
global skipWs:function
skipWs:
  mov rax, rdi

  ; while *rax == ' ' || *rax == '\n'
.loop:
  cmp BYTE [rax], ' '
  je .continue
  cmp BYTE [rax], 0xa
  je .continue
  ret

.continue:
  inc rax ; ++rax
  
  jmp .loop

;; rdi = start of string
;; sil = character to find
;; returns pointer to character
;; doesn't clobber
global findChar:function
findChar:
  mov rax, rdi

  ; while *rax != sil
.loop:
  cmp BYTE [rax], sil
  je .end

  inc rax ; ++rax
  
  jmp .loop
.end:

  ret

;; rdi = start of range to sort
;; rsi = end of range to sort
;; effect: sorts range
;; clobbers rax, rdi, rsi, rdx
global qsortLong:function
qsortLong:

  cmp rdi, rsi
  je .end

  ; stack slots:
  ; rsp+16 = pivot position
  ; rsp+8 = start of range
  ; rsp+0 = end of range
  sub rsp, 3*8

  mov [rsp + 8], rdi
  mov [rsp + 0], rsi

  ; for each element in the range (at least one)
  ; invariant: rdi = pivot address
  ; invariant: rdx = pivot value
  ; invariant: array looks like:
  ; x, x, x, x, x, x, x ...
  ; ^  ^  ^     ^
  ; |  |  |     + rsi = current element
  ; |  |  + rdi + 8 = greater than pivot
  ; |  + rdi = spot for pivot
  ; + rdi - 8 = less than pivot
  mov rdx, [rdi]
  mov rsi, rdi ; rsi = current node
.loop:

  cmp [rsi], rdx
  jge .noSwap ; if not greater than pivot, don't do anything

  mov rax, [rsi] ; insert rsi at current pivot position
  mov [rdi], rax
  
  mov rax, [rdi + 8] ; move greater than pivot to current position
  mov [rsi], rax

  add rdi, 8 ; move pivot position

.noSwap:
  add rsi, 8

  cmp rsi, [rsp + 0]
  jl .loop

  mov [rdi], rdx ; re-insert pivot
  mov [rsp + 16], rdi ; save pivot position

  mov rdi, [rsp + 8] ; rdi = start of range
  mov rsi, [rsp + 16] ; rsi = pivot position
  call qsortLong

  mov rdi, [rsp + 16] ; rdi = one more than pivot position
  add rdi, 8
  mov rsi, [rsp + 0] ; rsi = end of range
  call qsortLong

  add rsp, 3*8

.end:

  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns smallest element
;; clobbers rax, rdi
global minLong:function
minLong:
  mov rax, [rdi]

.loop:
  cmp [rdi], rax
  jge .continue

  mov rax, [rdi]

.continue:

  add rdi, 8

  cmp rdi, rsi
  jl .loop

  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns smallest element
;; clobbers rax, rdi
global maxLong:function
maxLong:
  mov rax, [rdi]

.loop:
  cmp [rdi], rax
  jle .continue

  mov rax, [rdi]

.continue:

  add rdi, 8

  cmp rdi, rsi
  jl .loop

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