;; OS interaction functions

section .text

;; memory map a file and return it's start and end
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

;; exit the program
;; dil = exit code
;; never returns
global exit:function
exit:
  mov rax, 60
  ; movzx rdi, dil ; truncated anyways
  syscall

;; allocate some memory
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

section .bss

statbuf: resb 144
oldbrk: resq 1
