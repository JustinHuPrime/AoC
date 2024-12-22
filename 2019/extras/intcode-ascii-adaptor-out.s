extern exit, putslong, newline

section .text

global _start:function
_start:
  mov rax, 0 ; read
  mov rdi, 0 ; from stdin
  lea rsi, [rsp - 8] ; to red zone
  mov rdx, 8 ; up to 8 bytes
  syscall
  
  test rax, rax
  jz .exit

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 8] ; from red zone
  mov rdx, 1 ; a byte
  syscall

  jmp _start
.exit:
  mov rdi, 0
  call exit