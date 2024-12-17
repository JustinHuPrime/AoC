extern exit, fputlong, putlong, newline

section .text

%define attempt r15

global _start:function
_start:
  mov attempt, 0

.tryLoop:
  mov rdi, attempt
  call putlong
  call newline
  
  mov rdi, attempt
  call run

  ; if outbuffer completely matches
  mov rdi, match
  mov rsi, outBuffer
  mov rcx, 16
  repe cmpsb
  je .endTryLoop

  ; if outbuffer matches a prefix
  std
  mov rcx, rax
  lea rsi, [outBuffer + rax - 1]
  mov rdi, match + 15
  repe cmpsb
  cld
  jne .continueTryLoop

  shl attempt, 3 ; allocate new space
  jmp .tryLoop ; don't increment

.continueTryLoop:
  inc attempt

  mov rax, attempt
  shr rax, 3
  test attempt, 0b111 ; looped around; find an alternative previous digit
  cmovz attempt, rax

  jmp .tryLoop
.endTryLoop:

  mov rdi, attempt
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = register A value to try
;; returns bytes outputted by program
run:
  sub rsp, 2 * 8
  ;; slots
  ;; rsp + 0 * 8, fd
  ;; rsp + 1 * 8, value to try

  mov [rsp + 1 * 8], rdi

  mov rax, 2 ; open
  mov rdi, sourceFilename ; filename
  mov rsi, 577 ; O_CREAT | O_TRUNC | O_WRONLY
  mov rdx, 0o664 ; u+rw g+rw o+r
  syscall
  mov [rsp + 0], rax

  mov rax, 1 ; write
  mov rdi, [rsp + 0 * 8] ; fd
  mov rsi, preRegA
  mov rdx, preRegA.end - preRegA
  syscall

  mov rdi, [rsp + 1 * 8] ; value to try
  mov rsi, [rsp + 0 * 8] ; fd
  call fputlong

  mov rax, 1 ; write
  mov rdi, [rsp + 0 * 8] ; fd
  mov rsi, postRegA
  mov rdx, postRegA.end - postRegA
  syscall

  mov rax, 3 ; close
  mov rdi, [rsp + 0 * 8] ; fd
  syscall

  mov rax, 57 ; fork
  syscall

  cmp rax, 0
  jne .notAssembler

  ; I'm the clone! set up fd for assembler and exec it
  mov rax, 2 ; open
  mov rdi, executableFilename ; filename
  mov rsi, 577 ; O_CREAT | O_TRUNC | O_WRONLY
  mov rdx, 0o775 ; u+rwx g+rwx o+rx
  syscall
  
  mov [rsp + 0 * 8], rax
  mov rax, 33 ; dup2
  mov rdi, [rsp + 0 * 8] ; copy executable
  mov rsi, 1 ; to stdout
  syscall

  mov rax, 3 ; close
  mov rdi, [rsp + 0 * 8] ; copy of executable
  syscall

  mov rax, 59 ; execve
  mov rdi, assemblerFilename
  mov rsi, assemblerArgv
  mov rdx, assemblerEnvp
  syscall

.notAssembler:

  mov rdi, rax ; the child
  mov rax, 61 ; wait4
  mov rsi, 0 ; no status
  mov rdx, 0 ; no options
  mov r10, 0 ; no usage stats
  syscall

  mov rax, 22 ; pipe
  mov rdi, rsp ; store to stack
  syscall

  mov rax, 57 ; fork
  syscall

  cmp rax, 0
  jne .notExecutable

  mov rax, 3 ; close
  mov edi, [rsp + 0 * 4] ; the read end
  syscall

  mov rax, 33 ; dup2
  mov edi, [rsp + 1 * 4] ; copy the write end
  mov rsi, 1 ; to stdout
  syscall

  mov rax, 3 ; close
  mov rdi, [rsp + 1 * 4] ; copy of the write end
  syscall

  mov rax, 59 ; execve
  mov rdi, executableFilename
  mov rsi, executableArgv
  mov rdx, executableEnvp
  syscall

.notExecutable:

  mov [rsp + 1 * 8], rax

  mov rax, 3 ; close
  mov edi, [rsp + 1 * 4] ; the write end
  syscall

  ; zero the out buffer
  mov rdi, outBuffer
  mov rax, 0
  mov rcx, 2
  rep stosq

  ; wait on the child
  mov rax, 61 ; wait4
  mov rdi, [rsp + 1 * 8] ; the child
  mov rsi, 0 ; no status
  mov rdx, 0 ; no options
  mov r10, 0 ; no usage stats
  syscall

  ; read from the pipe to the buffer
  mov rax, 0 ; read
  mov edi, [rsp + 0 * 4] ; the read end
  mov rsi, outBuffer
  mov rdx, 16
  syscall
  mov [rsp + 1 * 8], rax

  mov rax, 3 ; close
  mov edi, [rsp + 0 * 4] ; the read end
  syscall
  
  mov rax, [rsp + 1 * 8]
  add rsp, 2 * 8
  ret

section .rodata
preRegA: db "Register A: "
.end:
postRegA: db `\nRegister B: 0\nRegister C: 0\n\nProgram: 2,4,1,6,7,5,4,6,1,4,5,5,0,3,3,0\n`
.end:
match: db "2416754614550330"
.end:
sourceFilename: db `17b-attempt.txt\0`
executableFilename: db `17b-attempt\0`
assemblerFilename: db `./17a\0`
assemblerArgv:
  dq assemblerFilename
  dq sourceFilename
  dq 0
assemblerEnvp:
executableArgv:
executableEnvp:
  dq 0

section .bss
outBuffer: resb 16
