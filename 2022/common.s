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
  mov rsi, statBuffer
  syscall

  mov rax, 9 ; mmap
  mov r8, rdi ; r8 = opened fd
  mov rdi, 0 ; allocate a new address
  mov rsi, [statBuffer + 48] ; rsi = size of file (48 = offset into stat buffer of st_size)
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

;; no arguments
;; returns void
global newline:function
newline:
  mov BYTE [rsp - 1], 0xa

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 1] ; from red zone buffer
  mov rdx, 1 ; one byte
  syscall

  ret

;; rdi = unsigned long to write
;; returns void
global writeLong:function
writeLong:
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

section .bss

statBuffer: resb 144