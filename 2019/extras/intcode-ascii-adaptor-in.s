extern exit

section .text

global _start:function
_start:
  mov rax, 0 ; read
  mov rdi, 0 ; from stdin
  lea rsi, [rsp - 1] ; to red zone
  mov rdx, 1 ; a byte
  syscall

  test rax, rax
  jz .exit

  movsx rax, BYTE [rsp - 1]

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