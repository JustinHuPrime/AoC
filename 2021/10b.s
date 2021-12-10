section .text

extern writeNewline, writeLong, findWs, qsortLong

global _start:function
_start:
  ; get first argument
  mov rdi, [rsp + 16]

  mov rax, 2 ; open inputFile
  ; mov rdi, rdi ; already have input file name
  mov rsi, O_RDONLY
  mov rdx, 0
  syscall

  mov rdi, rax ; fstat opened inputFile
  mov rax, 5
  mov rsi, statBuf
  syscall
  mov rsi, [statBuf + sizeOffset] ; rsi = length of file
  mov r12, rdi ; r12 = fd

  mov rax, 9 ; mmap the file
  mov rdi, 0
  ; mov rsi, rsi ; already have size of file
  mov rdx, PROT_READ
  mov r10, MAP_PRIVATE
  mov r8, r12
  mov r9, 0
  syscall
  mov r15, rax ; r15 = current position in file

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  lea r12, [r15 + rsi] ; r12 = end position of file

  mov r14, parserStack ; r14 = next empty stack position
  mov r13, 0 ; r13 = current autocomplete score index
.loop:
  mov al, [r15] ; consider current character
  cmp al, '('
  jne .next1

  ; push '(' to the stack, advance position
  mov [r14], al
  inc r14
  inc r15

  jmp .done
.next1:
  cmp al, ')'
  jne .next2

  ; expect a '(', advance position
  dec r14
  mov al, [r14]
  inc r15
  cmp al, '('
  je .done

  mov r14, parserStack ; pop all of stack
  mov rdi, r15 ; skip past newline
  call findWs
  lea r15, [rax + 1]

  jmp .done
.next2:
  cmp al, '['
  jne .next3

  ; push '[' to the stack, advance position
  mov [r14], al
  inc r14
  inc r15

  jmp .done
.next3:
  cmp al, ']'
  jne .next4

  ; expect a '[', advance position
  dec r14
  mov al, [r14]
  inc r15
  cmp al, '['
  je .done

  mov r14, parserStack ; pop all of stack
  mov rdi, r15 ; skip past newline
  call findWs
  lea r15, [rax + 1]

  jmp .done
.next4:
  cmp al, '{'
  jne .next5

  ; push '{' to the stack, advance position
  mov [r14], al
  inc r14
  inc r15

  jmp .done
.next5:
  cmp al, '}'
  jne .next6

  ; expect a '{', advance position
  dec r14
  mov al, [r14]
  inc r15
  cmp al, '{'
  je .done

  mov r14, parserStack ; pop all of stack
  mov rdi, r15 ; skip past newline
  call findWs
  lea r15, [rax + 1]

  jmp .done
.next6:
  cmp al, '<'
  jne .next7

  ; push '<' to the stack, advance position
  mov [r14], al
  inc r14
  inc r15

  jmp .done
.next7:
  cmp al, '>'
  jne .next8

  ; expect a '<', advance position
  dec r14
  mov al, [r14]
  inc r15
  cmp al, '<'
  je .done

  mov r14, parserStack ; pop all of stack
  mov rdi, r15 ; skip past newline
  call findWs
  lea r15, [rax + 1]

  jmp .done
.next8:
  ; cmp al, 0xa ; statically known to be equal

  inc r15 ; skip newline

  ; do autocomplete
  mov r11, 0 ; r11 = autocomplete score so far
  mov r10, 5 ; r10 = constant 5
.complete:
  cmp r14, parserStack
  je .completed

  imul r11, r10

  dec r14
  mov al, [r14] ; consider character
  lea rdi, [r11 + 1] ; add the appropriate amount of score
  cmp al, '('
  cmove r11, rdi
  lea rdi, [r11 + 2]
  cmp al, '['
  cmove r11, rdi
  lea rdi, [r11 + 3]
  cmp al, '{'
  cmove r11, rdi
  lea rdi, [r11 + 4]
  cmp al, '<'
  cmove r11, rdi

  jmp .complete
.completed:

  test r11, r11
  jz .done

  mov [scores + (r13 * 8)], r11 ; save autocomplete score
  inc r13

  ; jmp .done ; fallthrough
.done:

  cmp r15, r12
  jl .loop

  mov rdi, scores
  lea rsi, [scores + (r13 * 8)]
  call qsortLong

  shr r13, 1
  mov rdi, [scores + (r13 * 8)]
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
parserStack:
  resb 1024
scores:
  resq 94