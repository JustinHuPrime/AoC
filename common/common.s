section .text

;; rdi = filename, as pointer to characters
;; returns:
;;   rax = mapped address of file
;;   rdx = length of file
;; note - leaks opened FD
global mmap:function
mmap:
  mov rax, 2 ; open
  ; mov rdi, rdi ; already have filename in correct register
  mov rsi, 0 ; flags = O_RDONLY
  ; mov rdx, 0 ; ignore mode
  syscall

  mov rdi, rax ; rdi = opened fd
  mov rax, 5 ; fstat
  mov rsi, statbuf
  syscall

  mov rax, 9 ; mmap
  mov r8, rdi ; r8 = opened fd
  mov rdi, 0 ; allocate a new address
  mov rsi, [statbuf + 48] ; rsi = size of file (48 = offset into stat buffer of st_size)
  mov rdx, 3 ; prot = PROT_READ | PROT_WRITE
  mov r10, 2 ; flags = MAP_PRIVATE
  mov r9, 0 ; no offset
  syscall

  ; mov rax, rax ; already have mmapped file in correct register
  mov rdx, rsi
  ret

;; dil = exit code
;; never returns
global exit:function
exit:
  mov rax, 60
  ; movzx rdi, dil ; truncated anyways
  syscall

;; rdi = start of string
;; rsi = end of string
;; returns integer value of string
;; clobbers rdi, rax, rdx, rcx
global atol:function
atol:
  mov rax, 0
  mov rdx, 10

  ; while rdi < rsi
.loop:
  cmp rdi, rsi
  jge .end

  imul rax, rdx ; rax *= 10

  mov cl, [rdi] ; rax += *current - 0
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
;; clobbers rdi, rax, rdx, rcx
global atosl:function
atosl:
  cmp BYTE [rdi], '-'
  jne .notNegative

  inc rdi
  call atol
  neg rax
  ret

.notNegative:
  jmp atol


;; dil = character to print
;; returns void
global putc:function
putc:
  mov [rsp - 1], dil

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 1] ; from red zone buffer
  mov rdx, 1 ; one byte
  syscall

  ret

;; rdi = character string to print
;; returns void
global puts:function
puts:
  mov rax, rdi
  mov rdx, 0

  ; get length of string
  ; while *rax != 0
.loop:
  cmp BYTE [rax], 0
  je .endLoop

  inc rax
  inc rdx

  jmp .loop
.endLoop:

  mov rax, 1 ; write
  mov rsi, rdi ; frmo given string
  mov rdi, 1 ; to stdout
  ; mov rdx, rdx ; with length gotten above
  syscall

  ret

;; no arguments
;; returns void
global newline:function
newline:
  mov dil, 0xa
  jmp putc

;; rdi = unsigned long to write
;; returns void
global putlong:function
putlong:
  ; special case: rdi = 0
  test rdi, rdi
  jnz .continue

  lea rdi, [rsp - 1]
  mov BYTE [rdi], '0'
  jmp .end

.continue:
  mov rax, rdi ; rax = number to write
  mov rdi, rsp ; rdi = start of string (in red zone)
  mov rsi, 10 ; rsi = const 10
  ; while rax != 0
.loop:
  test rax, rax
  jz .end

  dec rdi ; move one character further into red zone
  
  mov rdx, 0
  div rsi ; rax = quotient, rdx = remainder
  add dl, '0' ; dl = converted remainder

  mov [rdi], dl

  jmp .loop
.end:

  mov rax, 1 ; write
  mov rsi, rdi ; start from write buffer
  mov rdi, 1 ; to stdout
  mov rdx, rsp ; length = buffer end - current
  sub rdx, rsi
  syscall

  ret

;; rdi = signed long to write
;; returns void
global putslong:function
putslong:
  ; special case: rdi = 0
  test rdi, rdi
  jnz .continue

  lea rdi, [rsp - 1]
  mov BYTE [rdi], '0'
  jmp .write

.continue:

  mov r11, 0 ; r11 = sign flag
  mov rax, rdi ; rax = number to write
  mov rdi, rsp ; rdi = start of string (in red zone)
  test rax, rax
  jns .alreadyPositive

  neg rax
  mov r11, 1

.alreadyPositive:
  mov rsi, 10 ; rsi = const 10
  ; while rax != 0
.loop:
  test rax, rax
  jz .end

  dec rdi ; move one character further into red zone
  
  mov rdx, 0
  div rsi ; rax = quotient, rdx = remainder
  add dl, '0' ; dl = converted remainder

  mov [rdi], dl

  jmp .loop
.end:

  test r11, r11
  jz .write

  dec rdi
  mov BYTE [rdi], '-'

.write:

  mov rax, 1 ; write
  mov rsi, rdi ; start from write buffer
  mov rdi, 1 ; to stdout
  mov rdx, rsp ; length = buffer end - current
  sub rdx, rsi
  syscall

  ret

;; rdi = start of string
;; sil = character to search for
;; returns pointer to found character
;; noclobber
global findc:function
findc:
  mov rax, rdi

  ; while *rax != sil
.loop:
  cmp [rax], sil
  je .end

  inc rax ; ++rax

  jmp .loop
.end:

  ret

;; rdi = start of string
;; rsi = end of string
;; dl = character to search for
;; returns pointer to found character or end of string if not found
;; noclobber
global searchc:function
searchc:
  mov rax, rdi

  ; while rax < rsi
.loop:
  cmp rax, rsi
  jge .end

  cmp [rax], dl
  je .end

  inc rax

  jmp .loop
.end:

  ret

;; rdi = start of string
;; returns pointer to found newline
global findnl:function
findnl:
  mov sil, 0xa
  jmp findc

;; rdi = start of string
;; returns pointer to found space
global findspace:function
findspace:
  mov sil, ' '
  jmp findc

;; rdi = start of string
;; returns pointer to found comma
global findcomma:function
findcomma:
  mov sil, ','
  jmp findc

;; rdi = start of string
;; returns pointer to found whitespace
;; noclobber
global findws:function
findws:
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

;; rdi = start of string
;; returns pointer to character after whitespace
global skipws:function
skipws:
  mov rax, rdi

  ; while *rax == ' ' || *rax == '\n'
.loop:
  cmp BYTE [rax], ' '
  je .continue
  cmp BYTE [rax], 0xa
  je .continue

  ret

.continue:
  inc rax

  jmp .loop

;; rdi = start of string
;; rsi = end of string
;; dl = character to search for
;; returns count of characters found
global countc:function
countc:
  mov rax, 0

  ; do while rdi != rsi
.loop:
  lea rcx, [rax + 1]
  cmp BYTE [rdi], dl
  cmove rax, rcx

  inc rdi

  cmp rdi, rsi
  jl .loop

  ret

;; rdi = start of range to sort
;; rsi = end of range to sort
;; effect: sorts range
;; returns void
global qsort:function
qsort:
  ; if range is empty, return
  cmp rdi, rsi
  je .end

  ; stack slots:
  ; rsp+16 = pivot position
  ; rsp+8 = start of range
  ; rsp+0 = end of range
  sub rsp, 3*8

  mov [rsp + 0], rsi
  mov [rsp + 8], rdi

  ; for each element in the range (at least one)
  ; invariant: rdi = pivot address
  ; invariant: rdx = pivot value
  ; invariant: array looks like:
  ; x, x ... x, x, x ...
  ; ^  ^     ^
  ; |  |     + rsi = current element
  ; |  + rdi + 8 = greater than pivot
  ; + rdi = spot for pivot; value undefined
  mov rdx, [rdi]
  mov rsi, rdi ; rsi = current element
  ; do while rsi < end
.loop:

  cmp [rsi], rdx
  jge .continue ; not less than pivot and after pivot; do nothing

  mov rax, [rsi] ; insert rsi at current pivot position
  mov [rdi], rax
  
  mov rax, [rdi + 8] ; move greater than pivot to current position
  mov [rsi], rax

  add rdi, 8 ; move pivot position

.continue:
  add rsi, 8

  cmp rsi, [rsp + 0]
  jl .loop

  mov [rdi], rdx ; re-insert pivot
  mov [rsp + 16], rdi ; save pivot position

  mov rdi, [rsp + 8] ; rdi = start of range
  mov rsi, [rsp + 16] ; rsi = pivot position
  call qsort

  mov rdi, [rsp + 16] ; rdi = one more than pivot position
  add rdi, 8
  mov rsi, [rsp + 0] ; rsi = end of range
  call qsort

  add rsp, 3*8

.end:
  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns smallest element
global minlong:function
minlong:
  mov rax, [rdi] ; rax = smallest element

  ; do while rdi < rsi
.loop:
  mov rdx, [rdi] ; rdx = element value
  cmp rdx, rax ; if element < rax, rax = element
  cmovl rax, rdx

  add rdi, 8
  
  cmp rdi, rsi
  jl .loop

  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns address of smallest element
global argminlong:function
argminlong:
  mov rax, rdi ; rax = address of smallest element

  ; do while rdi < rsi
.loop:
  mov rdx, [rdi]
  cmp rdx, [rax] ; if element < rax, rax = &element
  cmovl rax, rdi

  add rdi, 8

  cmp rdi, rsi
  jl .loop

  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns largest element
global maxlong:function
maxlong:
  mov rax, [rdi] ; rax = smallest element

  ; do while rdi < rsi
.loop:
  mov rdx, [rdi] ; rdx = element value
  cmp rdx, rax ; if element > rax, rax = element
  cmovg rax, rdx

  add rdi, 8
  
  cmp rdi, rsi
  jl .loop

  ret

;; rdi = start of range to search
;; rsi = end of range to search
;; returns address of largest element
global argmaxlong:function
argmaxlong:
  mov rax, rdi ; rax = address of largest element

  ; do while rdi < rsi
.loop:
  mov rdx, [rdi]
  cmp rdx, [rax] ; if element > rax, rax = &element
  cmovg rax, rdi

  add rdi, 8

  cmp rdi, rsi
  jl .loop

  ret

;; rdi = length to allocate
;; returns pointer to allocation
;; clobbers rsi, rdi, rcx, r11
global alloc:function
alloc:
  mov rsi, rdi
  ; pad rdi out to the nearest 16 bytes
  test rsi, 0xf
  jz .nopad

  and rsi, ~0xf
  add rsi, 16

.nopad:
  cmp QWORD [oldbrk], 0
  jne .havebrk

  mov rax, 12 ; brk
  mov rdi, 0 ; impossible value
  syscall

  jmp .gotbrk

.havebrk:

  mov rax, [oldbrk]

.gotbrk:

  ; actually allocate
  lea rdi, [rax + rsi] ; rdi = old brk + length to allocate
  mov rsi, rax ; rsi = old brk
  mov rax, 12 ; brk
  syscall

  mov [oldbrk], rax ; save new brk

  mov rax, rsi ; return rsi (old brk)
  ret

;; dil = character to query
;; returns 0/1
global isnum:function
isnum:
  mov al, 0
  cmp dil, '0'
  jl .end
  cmp dil, '9'
  jg .end
  mov al, 1
.end:
  ret

;; rdi = start of string
;; returns pointer to found character
;; clobbers rdi, rsi
global findnotnum:function
findnotnum:
  mov rsi, rdi

  ; while !isnum(*rax)
.loop:
  mov dil, [rsi]
  call isnum
  test al, al
  jz .end

  inc rsi ; ++rax

  jmp .loop
.end:

  mov rax, rsi

  ret

;; rdi = first number (unsigned)
;; rsi = second number (unsigned)
;; computes LCM
global lcm:function
lcm:
  cmp rdi, rsi
  jge .noSwap
  
  mov rax, rdi
  mov rdi, rsi
  mov rsi, rax

.noSwap:

  mov rax, rdi
  mov rdx, 0
  mul rsi

  push rdx
  push rax

  call gcd

  mov rdi, rax

  pop rax
  pop rdx

  div rdi

  ret

;; rdi = first number (unsigned)
;; rsi = second number (unsigned), must be <= first number
;; computes GCD
global gcd:function
gcd:
  test rsi, rsi
  jnz .else

  mov rax, rdi
  ret

.else:
  mov rax, rdi
  mov rdx, 0
  div rsi
  mov rdi, rsi
  mov rsi, rdx
  jmp gcd

;; rdi = pointer to first string (zero-terminated)
;; rsi = pointer to second string (zero-terminated)
;; clobbers rdi, rsi, rdx
;; compares two strings, returns 1 if equal, 0 if not equal
global streq:function
streq:
  mov al, [rdi]
  or al, [rsi]
  test al, al
  jz .equal

  mov al, [rdi]
  mov dl, [rsi]
  cmp al, dl
  jnz .unequal

  inc rdi
  inc rsi
  jmp streq

.equal:
  mov al, 1
  ret

.unequal:
  mov al, 0
  ret

section .bss

statbuf: resb 144
oldbrk: resq 1