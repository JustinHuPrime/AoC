extern mmap, exit, newline, atol, findnl, putslong

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
  mov [outFile + 64+56+56+64 + 32], rax ; fill into section header

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
  dq 64+56+56 ; section header table pointer (after file and one program header)
  dd 0 ; no flags
  dw 64 ; size of header
  dw 56 ; program header table entry size
  dw 2 ; program header table entry count
  dw 64 ; section header table entry size
  dw 3 ; section header table entry count
  dw 0 ; section header table entry index for section names
programTextHeader: ; sizeof (programTextHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 0x5 ; load as read/execute
  dq 0x1000 ; load from 0x1000 onwards
  dq 0x400000 ; load into entry point
  dq 0 ; don't care about physical address
  dq 0 ; load <size> bytes
  dq 0 ; into <size> bytes
  dq 0x1000 ; page-align
programBssHeader: ; sizeof (programBssHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 6 ; load as read/write
  dq 0 ; no location in file
  dq 0x800000 ; to address 0x800000
  dq 0 ; don't care about physical address
  dq 0 ; load zero bytes
  dq 40*6 ; into sizeof(screen) bytes
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
bssSectionHeader: ; sizeof (bssSectionHeader) = 64
  dd 0 ; no name
  dd 8 ; bss section
  dq 3 ; allocate space for section, writable section
  dq 0x800000 ; at address 0x800000
  dq 0 ; from file offset zero (not used)
  dq 0 ; no size in file
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0x1000 ; page-align
  dq 0 ; no entry size
padding:
  db 0x1000-64-56-56-64-64-64 dup 0 ; pad out to 0x1000 for start of program text
endFileHeader:

setup:
  ; fill screen with spaces
  mov rcx, 40 * 6
  mov al, ' '
  mov rdi, 0x800000
  rep stosb

  mov r13, 1 ; r13 = x register
  mov r12, 1 ; r12 = clock
endSetup:

exitCode:
  ; write out screen buffer
  mov rcx, 6
.displayLoop:

  push rcx

  ; mov this line's 40 bytes onto the screen
  mov rsi, 6
  sub rsi, rcx
  mov rdi, 40
  imul rsi, rdi
  add rsi, 0x800000
  mov rcx, 40
  lea rdi, [rsp - 41]
  rep movsb

  mov BYTE [rdi], 0xa ; add newline

  mov rax, 1 ; write
  lea rsi, [rsp - 41] ; using redzone buffer
  mov rdi, 1 ; to stdout
  mov rdx, 41 ; 41 bytes
  syscall

  pop rcx

  loop .displayLoop

  ; exit
  mov dil, 0
  mov rax, 60
  syscall
endExitCode:

tick:
  ; if (r12 - 1) % 40 is within 1 of r13, mark screen[r12 - 1]
  lea rax, [r12 - 1]
  mov rdx, 0
  mov rdi, 40
  div rdi ; rdx = (r12 - 1) % 40

  ; get absolute value of (r12 - 1) % 40 - r13
  sub rdx, r13
  jns .positive
  
  neg rdx ; rdx < 0; rdx =-

.positive:

  cmp rdx, 1
  jg .noMark

  mov rax, 0x800000
  mov BYTE [rax + r12 - 1], '#'

.noMark:
  inc r12
endTick:

add:
  add r13, 0
endAdd:

section .bss
outFile:
  resq 16 * 1024