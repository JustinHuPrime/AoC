extern mmap, exit, newline, atol, findnl

section .text

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  mov r15, rax ; r15 = start of input
  lea r14, [rax + rdx] ; r14 = end of input

  mov r13, outFile ; r13 = file to write

  ; copy in program header
  mov rdi, r13
  mov rsi, fileHeader
  mov rcx, endFileHeader - fileHeader
  rep movsb
  mov r13, rdi

  ; copy in setup code
  mov rdi, r13
  mov rsi, setup
  mov rcx, endSetup - setup
  rep movsb
  mov r13, rdi

  ; while (r15 < r14)
.loop:
  cmp r15, r14
  jnl .endLoop

  ; read instruction
  cmp DWORD [r15], 'addx'
  jne .notAddx

  ; addx <literal>

  ; tick twice
  mov rdi, r13
  mov rsi, tick
  mov rcx, endTick - tick
  rep movsb
  mov rsi, tick
  mov rcx, endTick - tick
  rep movsb
  mov r13, rdi

  ; parse literal
  add r15, 5 ; skip "addx "

  cmp BYTE [r15], '-' ; is it negative?
  je .negativeLiteral

  ; positive

  ; parse it as is
  mov rdi, r15
  call findnl
  mov rdi, r15
  mov rsi, rax
  lea r15, [rax + 1] ; skip number + newline
  call atol

  jmp .readLiteral
.negativeLiteral:

  ; negative

  inc r15 ; skip negative sign

  ; parse it as is, then negate
  mov rdi, r15
  call findnl
  mov rdi, r15
  mov rsi, rax
  lea r15, [rax + 1] ; skip number + newline
  call atol
  neg rax

.readLiteral:

  ; add to r13
  mov rdi, r13
  mov rsi, add
  mov rcx, endAdd - add - 1
  rep movsb
  mov r13, rdi

  ; specify literal in template's location
  mov BYTE [r13], al
  inc r13

  jmp .assembledInstruction
.notAddx:
  cmp DWORD [r15], 'noop'
  jne .notNoop

  ; noop

  ; tick once
  mov rdi, r13
  mov rsi, tick
  mov rcx, endTick - tick
  rep movsb
  mov r13, rdi

  add r15, 5 ; skip "noop", newline

  jmp .assembledInstruction
.notNoop:
  ud2 ; illegal input
.assembledInstruction:

  jmp .loop
.endLoop:

  ; add exit
  mov rdi, r13
  mov rsi, exitCode
  mov rcx, endExitCode - exitCode
  rep movsb
  mov r13, rdi

  ; fill in blanks for size of text section
  mov rax, r13
  sub rax, outFile + 0x1000
  mov [outFile + 64 + 32], rax ; fill into program header
  mov [outFile + 64 + 40], rax
  mov [outFile + 64 + 56 + 64 + 32], rax ; fill into section header

  ; output file
  mov rax, 1 ; write
  mov rsi, outFile ; from start of output buffer
  mov rdi, 1 ; to stdout
  mov rdx, r13
  sub rdx, outFile ; length = buffer end - current
  syscall

  mov dil, 0
  call exit

section .rodata
fileHeader: ; sizeof (header) = 64, total size = 0x1000
  db 0x7f,'ELF' ; magic number
  db 2 ; 64 bit format
  db 1 ; little endian
  db 1 ; ELF version 1
  db 0 ; targetting generic SysV
  db 0 ; abi version ignored
  db 7 dup 0 ; 7 bytes padding
  dw 2 ; executable
  dw 0x3E ; x86_64
  dd 1 ; ELF version 1, again
  dq 0x400000 ; entry point
  dq 64 ; program header table pointer
  dq 64+56 ; section header table pointer (after file and one program header)
  dd 0 ; no flags
  dw 64 ; size of header
  dw 56 ; program header table entry size
  dw 1 ; program header table entry count
  dw 64 ; section header table entry size
  dw 2 ; section header table entry count
  dw 0 ; section header table entry index for section names
programHeader: ; sizeof (programHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 0x5 ; load as read/execute
  dq 0x1000 ; load from 0x1000 onwards
  dq 0x400000 ; load into entry point
  dq 0 ; don't care about physical address
  dq 0 ; load <size> bytes
  dq 0 ; into <size> bytes
  dq 0x1000 ; page-align
nullSectionHeader: ; sizeof (nullSectionHeader) = 64
  dd 0 ; no name
  dd 0 ; null section header type
  dq 0 ; no flags
  dq 0 ; not loaded
  dq 0 ; no offset
  dq 0 ; no size
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0 ; no alignment
  dq 0 ; no entry size
textSectionHeader: ; sizeof (textSectionHeader) = 64
  dd 0 ; no name
  dd 1 ; program data
  dq 6 ; allocate space for section, executable section
  dq 0x400000 ; load into start point
  dq 0x1000 ; load from 0x1000 onwards
  dq 0 ; into <size> bytes
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0x1000 ; page-align
  dq 0 ; no entry size
padding:
  db 0x1000-64-56-64-64 dup 0 ; pad out to 0x1000 for start of program text
endFileHeader:

setup:
  mov r13, 1 ; r13 = x register
  mov r12, 1 ; r12 = clock
  mov rbp, 0 ; rbp = accumulator
endSetup:

exitCode:
  ; setup for putslong
  mov rdi, rbp
  ; putslong
  ; special case: rdi = 0
  test rdi, rdi
  jnz .continue

  lea rdi, [rsp - 1]
  mov BYTE [rdi], '0'
  jmp .write

.continue:

  mov r11, 0 ; r11 = sign flag
  mov rax, rdi ; rax = number to write
  mov rdi, rsp ; rdi = start of string (in red zone)
  test rax, rax
  jns .alreadyPositive

  neg rax
  mov r11, 1

.alreadyPositive:
  mov rsi, 10 ; rsi = const 10
  ; while rax != 0
.loop:
  test rax, rax
  jz .end

  dec rdi ; move one character further into red zone
  
  mov rdx, 0
  div rsi ; rax = quotient, rdx = remainder
  add dl, '0' ; dl = converted remainder

  mov [rdi], dl

  jmp .loop
.end:

  test r11, r11
  jz .write

  dec rdi
  mov BYTE [rdi], '-'

.write:

  mov rax, 1 ; write
  mov rsi, rdi ; start from write buffer
  mov rdi, 1 ; to stdout
  mov rdx, rsp ; length = buffer end - current
  sub rdx, rsi
  syscall

  ; newline
  mov BYTE [rsp - 1], 0xa
  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 1] ; from red zone buffer
  mov rdx, 1 ; one byte
  syscall

  ; exit
  mov dil, 0
  mov rax, 60
  syscall
endExitCode:

tick:
  cmp r12, 20
  jl .noSignal
  mov rax, r12
  sub rax, 20
  cqo
  mov rsi, 40
  div rsi
  test rdx, rdx
  jnz .noSignal
  mov rax, r13
  imul rax, r12
  add rbp, rax
.noSignal:
  inc r12
endTick:

add:
  add r13, 0
endAdd:

section .bss
outFile:
  resq 16 * 1024