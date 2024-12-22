extern exit, findnotsnum, atosl

section .text

global _start:function
_start:
  mov rax, 0 ; read
  mov rdi, 0 ; from stdin
  lea rsi, [rsp - 32] ; to red zone
  mov rdx, 32 ; up to 32 bytes
  syscall

  test rax, rax
  jz .exit

  lea rdi, [rsp - 32]
  call findnotsnum
  lea rdi, [rsp - 32]
  mov rsi, rax
  call atosl

  mov [rsp - 8], rax
  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 8] ; from red zone
  mov rdx, 8 ; 8 bytes
  syscall

  jmp _start
.exit:
  mov rdi, 0
  call exit