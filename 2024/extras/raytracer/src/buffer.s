;; Framebuffer manipulation
;; Note that there is one global static framebuffer

%use fp

extern alloc

section .text

;; initializes frame buffer
global fbinit:function
fbinit:
  mov QWORD [framebufferEnd], framebuffer + framebufferHeaderEnd - framebufferHeader
  mov rdi, framebuffer
  mov rsi, framebufferHeader
  mov rcx, framebufferHeaderEnd - framebufferHeader
  rep movsb

  mov rax, framename + 7
.incrementNameLoop:
  inc BYTE [rax]

  cmp BYTE [rax], `9`
  jb .endIncrementNameLoop

  mov BYTE [rax], `0`
  dec rax

  jmp .incrementNameLoop
.endIncrementNameLoop:

  ret

;; writes frame buffer to file
global fbwrite:function
fbwrite:
  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = fd

  mov rax, 2 ; open
  mov rdi, framename
  mov rsi, 0o1 | 0o100 | 0o1000 ; O_WRONLY | O_CREAT | O_TRUNC
  mov rdx, 0o664 ; u+rw g+rw o+r
  syscall
  mov [rsp + 0], rax ; save fd

  mov rax, 1 ; write
  mov rdi, [rsp + 0]
  mov rsi, framebuffer
  mov rdx, [framebufferEnd]
  sub rdx, framebuffer
  syscall

  mov rax, 3 ; close
  mov rdi, [rsp + 0]
  syscall

  add rsp, 1 * 8
  ret

;; writes a pixel to the framebuffer
;; ymm0 = pixel data as rgb?
;;   where r = low order double
;;         b = second-high order double
;;         ? = high order double (ignored)
global fbpixel:function
fbpixel:
  sub rsp, 1 * 16
  ;; slots
  ;; rsp + 0 = unpacking buffer

  vbroadcastsd ymm1, [convertToByte]
  vmulpd ymm0, ymm0, ymm1
  vcvtpd2dq xmm0, ymm0
  movdqu [rsp + 0], xmm0 ; put into unpacking buffer

  mov dil, [rsp + 0]
  call fbpixelcomponent

  mov rax, [framebufferEnd]
  mov BYTE [rax], ' '
  inc QWORD [framebufferEnd]

  mov dil, [rsp + 4]
  call fbpixelcomponent

  mov rax, [framebufferEnd]
  mov BYTE [rax], ' '
  inc QWORD [framebufferEnd]

  mov dil, [rsp + 8]
  call fbpixelcomponent

  mov rax, [framebufferEnd]
  mov BYTE [rax], `\n`
  inc QWORD [framebufferEnd]

  add rsp, 1 * 16
  ret

;; writes a byte to the framebuffer
;; dil = byte to write
fbpixelcomponent:
  ; special case: dil = 0
  test dil, dil
  jnz .notZero

  mov rax, [framebufferEnd]
  mov BYTE [rax], '0'
  inc QWORD [framebufferEnd]
  ret

.notZero:

  ; while al != 0
  mov al, dil ; al = number to write
  mov rsi, rsp ; rsi = start of string (in red zone)
  mov r10b, 10 ; r10 = const 10
.loop:
  test al, al
  jz .endLoop

  dec rsi ; move one character further into red zone
  movzx ax, al
  div r10b
  mov dl, ah
  add dl, '0' ; dl = converted remainder

  mov [rsi], dl

  jmp .loop
.endLoop:

  ; mov rsi, rsi ; start from write buffer
  mov rdi, [framebufferEnd] ; to framebuffer
  mov rcx, rsp ; length = buffer end - current
  sub rcx, rsi
  add [framebufferEnd], rcx
  rep movsb ; copy into framebuffer

  ret

section .bss

framebuffer: resb framebufferHeaderEnd - framebufferHeader + 1920 * 1080 * 3 * 4
framebufferEnd: resq 1

section .rodata

framebufferHeader: db `P3\n1920 1080\n255\n`
framebufferHeaderEnd:
convertToByte: dq float64(255.99999)

section .data

framename: db `frame000.ppm\0`
