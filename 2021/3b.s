section .text

extern writeNewline, writeLong, atolBinary

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
  mov r13, rax ; r13 = start of file

  mov rax, 3 ; close file
  mov rdi, r12
  syscall

  lea r12, [r13 + rsi] ; r12 = end of file

  mov r11, 0 ; r11 = index of number considered

  ; while current < end (r13 = current position)
.countLoop:
  cmp r13, r12
  jge .countLoopEnd

  mov rdi, r13 ; read the number as a binary number
  lea rsi, [r13 + 12]
  call atolBinary
  mov [numbers + (r11 * 8)], rax

  add r13, 13 ; done this number
  inc r11 ; next number

  jmp .countLoop
.countLoopEnd:

  ; find o2 rating (most common bits)
  ; copy numbers into workspace1
  mov rsi, numbers
  mov rdi, workspace1
  mov rcx, 1000
  rep movsq

  mov rsi, workspace1 ; rsi = source list
  mov rdi, workspace2 ; rdi = destination list
  mov rdx, 1000 ; rdx = number of elements
  mov rax, 0x800 ; rax = mask
  ; do ... while moved count > 1
.o2Loop:

  ; search through the list for the most common mask bit set
  mov rbx, 0 ; rbx = count with mask bit set
  mov rcx, rdx
.o2LoopCount:

  lea r8, [rbx + 1]
  mov r9, [rsi + (rcx * 8) - 8] ; get the number
  test r9, rax ; if it's set
  cmovnz rbx, r8 ; add to the count with bit set

  loop .o2LoopCount

  ; move only those with that mask bit set/not set
  mov rcx, rdx
  mov rdx, 0 ; rdx = destination index
  mov r9, 0
  shl rbx, 1 ; if 2 * count with bit set > total, then more are set than not
  cmp rbx, rcx
  cmovge r9, rax ; r9 = desired masked value
.o2LoopMove:

  mov r8, [rsi + (rcx * 8) - 8] ; get the number again
  mov r10, r8
  and r8, rax ; extract the bit
  cmp r8, r9 ; if it's the desired value
  jne .o2NoMove

  mov [rdi + (rdx * 8)], r10 ; move the number
  inc rdx

.o2NoMove:
  
  loop .o2LoopMove

  shr rax, 1 ; next mask value

  mov rcx, rsi ; swap src and dest lists
  mov rsi, rdi
  mov rdi, rcx

  cmp rdx, 1
  jne .o2Loop

  mov r15, [rsi] ; r14 = o2 rating

  ; find co2 rating (most common bits)
  ; copy numbers into workspace1
  mov rsi, numbers
  mov rdi, workspace1
  mov rcx, 1000
  rep movsq

  mov rsi, workspace1 ; rsi = source list
  mov rdi, workspace2 ; rdi = destination list
  mov rdx, 1000 ; rdx = number of elements
  mov rax, 0x800 ; rax = mask
  ; do ... while moved count > 1
.co2Loop:

  ; search through the list for the most common mask bit set
  mov rbx, 0 ; rbx = count with mask bit set
  mov rcx, rdx
.co2LoopCount:

  lea r8, [rbx + 1]
  mov r9, [rsi + (rcx * 8) - 8] ; get the number
  test r9, rax ; if it's set
  cmovnz rbx, r8 ; add to the count with bit set

  loop .co2LoopCount

  ; move only those with that mask bit set/not set
  mov rcx, rdx
  mov rdx, 0 ; rdx = destination index
  mov r9, 0
  shl rbx, 1 ; if 2 * count with bit set > total, then more are set than not
  cmp rbx, rcx
  cmovge r9, rax ; r9 = undesired masked value
.co2LoopMove:

  mov r8, [rsi + (rcx * 8) - 8] ; get the number again
  mov r10, r8
  and r8, rax ; extract the bit
  cmp r8, r9 ; if it's the undesired value
  je .co2NoMove

  mov [rdi + (rdx * 8)], r10 ; move the number
  inc rdx

.co2NoMove:
  
  loop .co2LoopMove

  shr rax, 1 ; next mask value

  mov rcx, rsi ; swap src and dest lists
  mov rsi, rdi
  mov rdi, rcx

  cmp rdx, 1
  jne .co2Loop

  mov rdi, [rsi] ; rdi = co2 rating

  imul rdi, r15
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
numbers:
  resq 1000
workspace1:
  resq 1000
workspace2:
  resq 1000