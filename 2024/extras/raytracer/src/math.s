;; Mathmatical functions

;; type Vec3 = YMMWORD
;; struct Ray {
;;   YMMWORD origin
;;   YMMWORD direction
;; }

section .text

;; produces unit vector
;; ymm0 = vector
;; returns unit vector
global vec3_unit:function
vec3_unit:
  sub rsp, 1 * 32
  ;; slots
  ;; rsp + 0: vector

  vmovupd [rsp + 0], ymm0
  
  ; vector / length(vector)
  call vec3_length
  vbroadcastsd ymm1, xmm0
  vmovupd ymm0, [rsp + 0]
  vdivpd ymm0, ymm0, ymm1

  add rsp, 1 * 32
  ret

;; produces length of vector
;; ymm0 = vector
;; returns length
global vec3_length:function
vec3_length:
  call vec3_squared_length
  sqrtsd xmm0, xmm0
  ret

;; produces squared length of vector
;; ymm0 = vector
;; returns squared length
global vec3_squared_length:function
vec3_squared_length:
  vmulpd ymm0, ymm0, ymm0
  vmovupd [rsp - 32], ymm0
  movsd xmm0, [rsp - 32]
  addsd xmm0, [rsp - 24]
  addsd xmm0, [rsp - 16]
  ret
