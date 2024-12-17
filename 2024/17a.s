extern exit, mmap, findnl, atol

section .text

%define currChar r12
%define endOfFile QWORD [rsp + 0]
%define writePtr r13
%define currAddr r14

%define regA r12
%define regB r13
%define regC r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0, endOfFile

  mov currChar, rax
  add rdx, rax
  mov endOfFile, rdx

  mov writePtr, outFile

  ; copy in program header
  mov rdi, writePtr
  mov rsi, fileHeader
  mov rcx, 0x1000
  rep movsb
  mov writePtr, rdi

  ; copy in init code
  mov rdi, writePtr
  mov rsi, b3init
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; fill in starting register values
  add currChar, 12 ; skip "Register A: "
  mov rdi, currChar
  call findnl
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [writePtr - 64 + 2], rax

  add currChar, 13 ; skip "\nRegister B: "
  mov rdi, currChar
  call findnl
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [writePtr - 64 + 10 + 2], rax

  add currChar, 13 ; skip "\nRegister C: "
  mov rdi, currChar
  call findnl
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atol
  mov [writePtr - 64 + 20 + 2], rax

  add currChar, 11 ; skip "\n\nProgram: "

  mov currAddr, 0
  add currChar, 2
.assembleLoop:

  ; need to assemble nonaligned instructions too, just in case!
  sub currChar, 2
  mov r8b, [currChar]
  sub r8b, '0'
  add currChar, 2
  mov r9b, [currChar]
  sub r9b, '0'
  add currChar, 2

  ; r8b = opcode, r9b = operand
  cmp r8b, 0
  jne .notAdv

  cmp r9b, 3
  ja .notAdvImm

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3advImm
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 3], r9b

  jmp .continueAssembleLoop
.notAdvImm:

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3advReg
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch register
  cmp r9b, 4
  jne .notAdvA

  mov BYTE [writePtr - 64 + 2], 0xe1

  jmp .continueAssembleLoop
.notAdvA:

  cmp r9b, 5
  jne .notAdvB

  mov BYTE [writePtr - 64 + 2], 0xe9

  jmp .continueAssembleLoop
.notAdvB:

  cmp r9b, 6
  jne .notAdvC

  mov BYTE [writePtr - 64 + 2], 0xf1

  jmp .continueAssembleLoop
.notAdvC:

  jmp .continueAssembleLoop ; invalid operand, don't patch
  
.notAdv:

  cmp r8b, 1
  jne .notBxl

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bxl
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 3], r9b

  jmp .continueAssembleLoop
.notBxl:

  cmp r8b, 2
  jne .notBst

  cmp r9b, 3
  ja .notBstImm

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bstImm
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 2], r9b

  jmp .continueAssembleLoop
.notBstImm:

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bstReg
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch register
  cmp r9b, 4
  jne .notBstA

  mov BYTE [writePtr - 64 + 2], 0xe5

  jmp .continueAssembleLoop
.notBstA:

  cmp r9b, 5
  jne .notBstB

  mov BYTE [writePtr - 64 + 2], 0xed

  jmp .continueAssembleLoop
.notBstB:

  cmp r9b, 6
  jne .notBstC

  mov BYTE [writePtr - 64 + 2], 0xf5

  jmp .continueAssembleLoop
.notBstC:

  jmp .continueAssembleLoop ; invalid operand, don't patch

.notBst:

  cmp r8b, 3
  jne .notJnz

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3jnz
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov rax, 0x400000 + 64
  movzx rsi, r9b
  shl rsi, 6
  add rax, rsi
  mov [writePtr - 64 + 7], rax

  jmp .continueAssembleLoop
.notJnz:

  cmp r8b, 4
  jne .notBxc

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bxc
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  jmp .continueAssembleLoop
.notBxc:

  cmp r8b, 5
  jne .notOut

  cmp r9b, 3
  ja .notOutImm

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3outImm
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 4], r9b

  jmp .continueAssembleLoop
.notOutImm:

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3outReg
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch register
  cmp r9b, 4
  jne .notOutA

  mov BYTE [writePtr - 64 + 2], 0x64

  jmp .continueAssembleLoop
.notOutA:

  cmp r9b, 5
  jne .notOutB

  mov BYTE [writePtr - 64 + 2], 0x6c

  jmp .continueAssembleLoop
.notOutB:

  cmp r9b, 6
  jne .notOutC

  mov BYTE [writePtr - 64 + 2], 0x74

  jmp .continueAssembleLoop
.notOutC:

  jmp .continueAssembleLoop ; invalid operand, don't patch

.notOut:

  cmp r8b, 6
  jne .notBdv

  cmp r9b, 3
  ja .notBdvImm

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bdvImm
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 6], r9b

  jmp .continueAssembleLoop
.notBdvImm:

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3bdvReg
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch register
  cmp r9b, 4
  jne .notBdvA

  mov BYTE [writePtr - 64 + 5], 0xe1

  jmp .continueAssembleLoop
.notBdvA:

  cmp r9b, 5
  jne .notBdvB

  mov BYTE [writePtr - 64 + 5], 0xe9

  jmp .continueAssembleLoop
.notBdvB:

  cmp r9b, 6
  jne .notBdvC

  mov BYTE [writePtr - 64 + 5], 0xf1

  jmp .continueAssembleLoop
.notBdvC:

  jmp .continueAssembleLoop ; invalid operand, don't patch

.notBdv:

  cmp r8b, 7
  jne .notCdv

  cmp r9b, 3
  ja .notCdvImm

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3cdvImm
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch immediate
  mov [writePtr - 64 + 6], r9b

  jmp .continueAssembleLoop
.notCdvImm:

  ; output instruction
  mov rdi, writePtr
  mov rsi, b3cdvReg
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; patch register
  cmp r9b, 4
  jne .notCdvA

  mov BYTE [writePtr - 64 + 5], 0xe1

  jmp .continueAssembleLoop
.notCdvA:

  cmp r9b, 5
  jne .notCdvB

  mov BYTE [writePtr - 64 + 5], 0xe9

  jmp .continueAssembleLoop
.notCdvB:

  cmp r9b, 6
  jne .notCdvC

  mov BYTE [writePtr - 64 + 5], 0xf1

  jmp .continueAssembleLoop
.notCdvC:

  jmp .continueAssembleLoop ; invalid operand, don't patch

.notCdv:

  ud2 ; invalid opcode

.continueAssembleLoop:

  inc currAddr

  cmp currChar, endOfFile
  jb .assembleLoop

  ; emit halt (twice)
  mov rdi, writePtr
  mov rsi, b3halt
  mov rcx, 64
  rep movsb
  mov rsi, b3halt
  mov rcx, 64
  rep movsb
  mov writePtr, rdi

  ; fill in blanks for size of text section
  mov rax, writePtr
  sub rax, outFile + 0x1000
  mov [outFile + 64 + 32], rax ; fill into program header
  mov [outFile + 64 + 40], rax
  mov [outFile + 64 + 56 + 64 + 32], rax ; fill into section header

  ; output file
  mov rax, 1 ; write
  mov rsi, outFile ; from start of output buffer
  mov rdi, 1 ; to stdout
  mov rdx, writePtr
  sub rdx, outFile ; length = buffer end - current
  syscall

  mov dil, 0
  call exit

section .rodata
b3init:
  mov regA, 0x1111111111111111
  mov regB, 0x2222222222222222
  mov regC, 0x3333333333333333
  jmp .end
  times 64 - ($ - b3init) nop
.end:
b3advImm: ; combo operand (immediate type)
  shr regA, 0x7
  jmp .end + 64
  times 64 - ($ - b3advImm) nop
.end:
b3advReg: ; combo operand (register type)
  mov cl, r15b
  shr regA, cl
  jmp .end + 64
  times 64 - ($ - b3advReg) nop
.end:
b3bxl: ; literal operand
  xor regB, 0x7
  jmp .end + 64
  times 64 - ($ - b3bxl) nop
.end:
b3bstImm: ; combo operand (immediate type)
  mov regB, 0x7
  jmp .end + 64
  times 64 - ($ - b3bstImm) nop
.end:
b3bstReg: ; combo operand (register type)
  mov regB, r15
  and regB, 0b111
  jmp .end + 64
  times 64 - ($ - b3bstReg) nop
.end:
b3jnz: ; literal operand
  test regA, regA
  jz .skip
  mov rax, 0x1111111111111111
  jmp rax
.skip:
  jmp .end + 64
  times 64 - ($ - b3jnz) nop
.end:
b3bxc: ; ignored operand
  xor regB, regC
  jmp .end + 64
  times 64 - ($ - b3bxc) nop
.end:
b3outImm: ; combo operand (immediate type)
  mov BYTE [rsp - 1], 0x7
  add BYTE [rsp - 1], '0'
  mov rax, 1
  mov rdi, 1
  lea rsi, [rsp - 1]
  mov rdx, 1
  syscall
  jmp .end + 64
  times 64 - ($ - b3outImm) nop
.end:
b3outReg: ; combo operand (register type)
  mov [rsp - 1], r15b
  and BYTE [rsp - 1], 0b111
  add BYTE [rsp - 1], '0'
  mov rax, 1
  mov rdi, 1
  lea rsi, [rsp - 1]
  mov rdx, 1
  syscall
  jmp .end + 64
  times 64 - ($ - b3outReg) nop
.end:
b3bdvImm: ; combo operand (immediate type)
  mov regB, regA
  shr regB, 0x7
  jmp .end + 64
  times 64 - ($ - b3bdvImm) nop
.end:
b3bdvReg: ; combo operand (register type)
  mov regB, regA
  mov cl, r15b
  shr regB, cl
  jmp .end + 64
  times 64 - ($ - b3bdvReg) nop
.end:
b3cdvImm: ; combo operand (immediate type)
  mov regC, regA
  shr regC, 0x7
  jmp .end + 64
  times 64 - ($ - b3cdvImm) nop
.end:
b3cdvReg: ; combo operand (register type)
  mov regC, regA
  mov cl, r15b
  shr regC, cl
  jmp .end + 64
  times 64 - ($ - b3cdvReg) nop
.end:
b3halt:
  mov dil, 0
  mov rax, 60
  syscall
  jmp .end + 64
  times 64 - ($ - b3halt) nop
.end:

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
  dq 64 + 56 ; section header table pointer (after file and one program header)
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
  db 0x1000 - ($ - fileHeader) dup 0 ; pad out to 0x1000 for start of program text

section .bss
outFile: resb 16384