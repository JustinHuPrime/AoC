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

  mov rdi, [rsp - 8]
  call putslong
  call newline

  jmp _start
.exit:
  mov rdi, 0
  call exit