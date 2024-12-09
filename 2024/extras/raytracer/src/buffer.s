;; Framebuffer manipulation
;; Note that there is one global static framebuffer

%use fp

section .text

;; initializes frame buffer
global fb_init:function
fb_init:
  mov QWORD [framebuffer_end], framebuffer + framebuffer_header.end - framebuffer_header
  mov rdi, framebuffer
  mov rsi, framebuffer_header
  mov rcx, framebuffer_header.end - framebuffer_header
  rep movsb

  mov rax, frame_name + 7
.increment_name_loop:
  inc BYTE [rax]

  cmp BYTE [rax], `9`
  jb .end_increment_name_loop

  mov BYTE [rax], `0`
  dec rax

  jmp .increment_name_loop
.end_increment_name_loop:

  ret

;; writes frame buffer to file
global fb_write:function
fb_write:
  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = fd

  mov rax, 2 ; open
  mov rdi, frame_name
  mov rsi, 0o1 | 0o100 | 0o1000 ; O_WRONLY | O_CREAT | O_TRUNC
  mov rdx, 0o664 ; u+rw g+rw o+r
  syscall
  mov [rsp + 0], rax ; save fd

  mov rax, 1 ; write
  mov rdi, [rsp + 0]
  mov rsi, framebuffer
  mov rdx, [framebuffer_end]
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
global fb_pixel:function
fb_pixel:
  sub rsp, 1 * 16
  ;; slots
  ;; rsp + 0 = unpacking buffer

  vbroadcastsd ymm1, [convert_to_byte]
  vmulpd ymm0, ymm0, ymm1
  vroundpd ymm0, ymm0, 0x3
  vcvtpd2dq xmm0, ymm0
  movdqu [rsp + 0], xmm0 ; put into unpacking buffer

  mov dil, [rsp + 0]
  call fb_pixel_component

  mov rax, [framebuffer_end]
  mov BYTE [rax], ' '
  inc QWORD [framebuffer_end]

  mov dil, [rsp + 4]
  call fb_pixel_component

  mov rax, [framebuffer_end]
  mov BYTE [rax], ' '
  inc QWORD [framebuffer_end]

  mov dil, [rsp + 8]
  call fb_pixel_component

  mov rax, [framebuffer_end]
  mov BYTE [rax], `\n`
  inc QWORD [framebuffer_end]

  add rsp, 1 * 16
  ret

;; writes a byte to the framebuffer
;; dil = byte to write
fb_pixel_component:
  ; special case: dil = 0
  test dil, dil
  jnz .not_zero

  mov rax, [framebuffer_end]
  mov BYTE [rax], '0'
  inc QWORD [framebuffer_end]
  ret

.not_zero:

  ; while al != 0
  mov al, dil ; al = number to write
  mov rsi, rsp ; rsi = start of string (in red zone)
  mov r10b, 10 ; r10 = const 10
.loop:
  test al, al
  jz .end_loop

  dec rsi ; move one character further into red zone
  movzx ax, al
  div r10b
  mov dl, ah
  add dl, '0' ; dl = converted remainder

  mov [rsi], dl

  jmp .loop
.end_loop:

  ; mov rsi, rsi ; start from write buffer
  mov rdi, [framebuffer_end] ; to framebuffer
  mov rcx, rsp ; length = buffer end - current
  sub rcx, rsi
  add [framebuffer_end], rcx
  rep movsb ; copy into framebuffer

  ret

section .bss

framebuffer: resb framebuffer_header.end - framebuffer_header + 1920 * 1080 * 3 * 4
framebuffer_end: resq 1

section .rodata

framebuffer_header: db `P3\n1920 1080\n255\n`
.end:
convert_to_byte: dq float64(255.99999)

section .data

frame_name: db `frame000.ppm\0`
