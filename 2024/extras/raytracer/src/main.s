;; Raytracing in One Weekend in assembly
;; (https://raytracing.github.io/books/RayTracingInOneWeekend.html)

%use fp

extern mmap, exit, fbinit, fbwrite, fbpixel

section .text
global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ; sub rsp, 0 * 8
  ;; slots

  call fbinit

  mov r12, 0 ; r12 = y
.yLoop:

  mov r13, 0 ; r13 = x
.xLoop:

  ; r = double(r13) / 1920 - 1
  ; g = double(r12) / 1080 - 1
  ; b = 0
  ; g = 0
  mov [rsp - 16], r13d
  mov [rsp - 12], r12d
  mov DWORD [rsp - 8], 0
  mov DWORD [rsp - 4], 0
  vcvtdq2pd ymm0, [rsp - 16]
  vdivpd ymm0, ymm0, [convertVector]
  call fbpixel

  inc r13

  cmp r13, 1920
  jb .xLoop

  inc r12

  cmp r12, 1080
  jb .yLoop

  call fbwrite

  mov dil, 0
  call exit

.rodata:

convertVector:
  dq float64(1919.0), float64(1079.0), float64(1.0), float64(1.0)
