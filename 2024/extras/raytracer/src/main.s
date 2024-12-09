;; Raytracing in One Weekend in assembly
;; (https://raytracing.github.io/books/RayTracingInOneWeekend.html)

%use fp

extern mmap, exit, fb_init, fb_write, fb_pixel, vec3_unit

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 64 + 4 * 32
  ;; slots
  ;; rsp + 0: ray
  ;; rsp + 64: camera_center
  ;; rsp + 96: pixel00_loc
  ;; rsp + 128: pixel_delta_u
  ;; rsp + 160: pixel_delta_v

  ; focal_length = 1.0
  movsd xmm1, [focal_length]
  mov QWORD [rsp - 32], 0
  mov QWORD [rsp - 24], 0
  movsd [rsp - 16], xmm1
  mov QWORD [rsp - 8], 0
  vmovupd ymm1, [rsp - 32]

  ; viewport_height = 2.0
  movsd xmm2, [viewport_height]
  ; viewport_width = viewport_height * width/height
  movsd xmm3, xmm2
  mulsd xmm3, [width_v]
  divsd xmm3, [height_v]

  ; camera_center = vec3(0, 0, 0)
  vxorpd ymm0, ymm0, ymm0
  vmovupd [rsp + 64], ymm0

  ; viewport_u = vec3(viewport_width, 0, 0)
  movsd [rsp - 32], xmm3
  mov QWORD [rsp - 24], 0
  mov QWORD [rsp - 16], 0
  mov QWORD [rsp - 8], 0
  vmovupd ymm3, [rsp - 32]

  ; viewport_v = vec3(0, -viewport_height, 0)
  xorpd xmm2, [negate]
  mov QWORD [rsp - 32], 0
  movsd [rsp - 24], xmm2
  mov QWORD [rsp - 16], 0
  mov QWORD [rsp - 8], 0
  vmovupd ymm2, [rsp - 32]

  ; pixel_delta_u = viewport_u / width
  vdivpd ymm0, ymm3, [width_v]
  vmovupd [rsp + 128], ymm0

  ; pixel_delta_v = viewport_v / height
  vdivpd ymm0, ymm2, [height_v]
  vmovupd [rsp + 160], ymm0

  ; viewport_upper_left = camera_center - vec3(0, 0, focal_length) - viewport_u / 2 - viewport_v / 2
  vmovupd ymm0, [rsp + 64]
  vsubpd ymm0, ymm0, ymm1
  vfnmadd231pd ymm0, ymm3, [half] ; ymm0 = ymm0 - (ymm3 * [half])
  vfnmadd231pd ymm0, ymm2, [half] ; ymm0 = ymm0 - (ymm2 * [half])
  ; pixel00_loc = viewport_upper_left + 0.5 * (pixel_delta_u + pixel_delta_v)
  vmovupd ymm3, [rsp + 128]
  vfmadd231pd ymm0, ymm3, [half] ; ymm0 = ymm0 + (ymm3 * [half])
  vmovupd ymm2, [rsp + 160]
  vfmadd231pd ymm0, ymm2, [half] ; ymm0 = ymm0 + (ymm3 * [half])
  vmovupd [rsp + 96], ymm0

  call fb_init

  mov r12, 0 ; r12 = y
.y_loop:

  mov r13, 0 ; r13 = x
.x_loop:

  ; pixel_center = pixel00_loc + (r13 * pixel_delta_u) + (r12 * pixel_delta_v)
  ; ray_direction = pixel_center - camera_center
  ; ray = ray(camera_center, ray_direction)
  vmovupd ymm0, [rsp + 64]
  vmovupd [rsp + 0], ymm0

  vmovupd ymm0, [rsp + 96]
  cvtsi2sd xmm1, r13
  vbroadcastsd ymm1, xmm1
  vfmadd231pd ymm0, ymm1, [rsp + 128]
  cvtsi2sd xmm1, r12
  vbroadcastsd ymm1, xmm1
  vfmadd231pd ymm0, ymm1, [rsp + 160]
  vmovupd [rsp + 32], ymm0

  lea rdi, [rsp + 0]
  call ray_colour
  call fb_pixel

  inc r13

  cmp r13, [width]
  jb .x_loop

  inc r12

  cmp r12, [height]
  jb .y_loop

  call fb_write

  mov dil, 0
  call exit

ray_colour:
  ; form unit vector of direction
  vmovupd ymm0, [rdi + 32]
  call vec3_unit
  ; extract y-dimension
  vmovupd [rsp - 32], ymm0
  movsd xmm1, [rsp - 24]

  ; a = 0.5 * y + 0.5
  movsd xmm2, [half]
  vfmadd213sd xmm1, xmm2, xmm2
  ; ymm2 = 1.0 - a
  movsd xmm2, [one]
  subsd xmm2, xmm1
  vbroadcastsd ymm2, xmm2
  ; ymm1 = a
  vbroadcastsd ymm1, xmm1

  ; a * light_blue + (1.0 - a) * white
  vmulpd ymm0, ymm1, [light_blue]
  vfmadd231pd ymm0, ymm2, [white]
  
  ret

.rodata:

focal_length: dq float64(1.0)
viewport_height: dq float64(2.0)
width: dq 1920
height: dq 1080
one: dq float64(1.0)
align 32
width_v: dq float64(1920.0), float64(1920.0), float64(1920.0), float64(1.0)
align 32
height_v: dq float64(1080.0), float64(1080.0), float64(1080.0), float64(1.0)
align 32
negate: dq 0x8000000000000000, 0x8000000000000000, 0x8000000000000000, 0x0000000000000000
align 32
half: dq float64(0.5), float64(0.5), float64(0.5), float64(1.0)
align 32
white: dq float64(1.0), float64(1.0), float64(1.0), float64(1.0)
align 32
light_blue: dq float64(0.5), float64(0.7), float64(1.0), float64(1.0)
