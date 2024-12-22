extern exit, mmap, findnotsnum, atosl

section .text

%define startOfFile QWORD [rsp + 8]
%define endOfFile QWORD [rsp + 0]

%define currChar r12
%define codePtr r13
%define dataPtr r14
%define rodataPtr r15

%define instructionSize 256
%define log2InstructionSize 8

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0, endOfFile
  ;; rsp + 8, startOfFile

  mov startOfFile, rax
  add rdx, rax
  mov endOfFile, rdx

  mov codePtr, outCode

  mov rdi, codePtr
  mov rsi, intcodeinit
  mov rcx, 0x1000
  rep movsb
  mov codePtr, rdi

  mov dataPtr, outData
  mov currChar, startOfFile
.assembleLoop:

  ; read an int
  mov rdi, currChar
  call findnotsnum
  mov rdi, currChar
  mov rsi, rax
  mov currChar, rax
  call atosl

  ; assemble rax

  ; as data
  mov [dataPtr], rax
  add dataPtr, 8

  ; as code

  mov rdx, 0
  mov rdi, 100
  div rdi
  mov rax, rdx

  ; add
  cmp rax, 1
  jne .notAdd

  mov rdi, codePtr
  mov rsi, intcodeadd
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notAdd:

  ; mul
  cmp rax, 2
  jne .notMul

  mov rdi, codePtr
  mov rsi, intcodemul
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notMul:

  ; in
  cmp rax, 3
  jne .notIn

  mov rdi, codePtr
  mov rsi, intcodein
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notIn:

  ; out
  cmp rax, 4
  jne .notOut

  mov rdi, codePtr
  mov rsi, intcodeout
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notOut:

  ; jnz
  cmp rax, 5
  jne .notJnz

  mov rdi, codePtr
  mov rsi, intcodejnz
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notJnz:

  ; jz
  cmp rax, 6
  jne .notJz

  mov rdi, codePtr
  mov rsi, intcodejz
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notJz:

  ; lt
  cmp rax, 7
  jne .notLt

  mov rdi, codePtr
  mov rsi, intcodelt
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notLt:

  ; eq
  cmp rax, 8
  jne .notEq

  mov rdi, codePtr
  mov rsi, intcodeeq
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notEq:

  ; srel
  cmp rax, 9
  jne .notSrel

  mov rdi, codePtr
  mov rsi, intcodesrel
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notSrel:

  ; halt
  cmp rax, 99
  jne .notHalt

  mov rdi, codePtr
  mov rsi, intcodehalt
  mov rcx, instructionSize
  rep movsb
  mov codePtr, rdi

  jmp .continueAssembleLoop
.notHalt:

  ; not recognized - fill with zeroes
  mov al, 0
  mov rdi, codePtr
  mov rcx, instructionSize
  rep stosb
  mov codePtr, rdi

.continueAssembleLoop:

  inc currChar ; move to next int

  cmp currChar, endOfFile
  jb .assembleLoop

  ; fill in rodata table
  mov rodataPtr, outRodata

  mov al, 0
  mov rdi, rodataPtr
  mov rcx, instructionSize
  rep stosb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodeadd
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodemul
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodein
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodeout
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodejnz
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodejz
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodelt
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodeeq
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodesrel
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  mov al, 0
  mov rdi, rodataPtr
  mov rcx, instructionSize * (98 - 9)
  rep stosb
  mov rodataPtr, rdi

  mov rdi, rodataPtr
  mov rsi, intcodehalt
  mov rcx, instructionSize
  rep movsb
  mov rodataPtr, rdi

  ; fill in section size info
  sub codePtr, outCode
  add codePtr, 0xfff
  and codePtr, ~0xfff
  mov [programTextHeader.len], codePtr
  add [programDataHeader.offset], codePtr
  add [programRodataHeader.offset], codePtr
  mov [textSectionHeader.len], codePtr
  add [dataSectionHeader.offset], codePtr
  add [rodataSectionHeader.offset], codePtr

  sub dataPtr, outData
  add dataPtr, 0xfff
  and dataPtr, ~0xfff
  mov [programDataHeader.len], dataPtr
  add [programRodataHeader.offset], dataPtr
  mov [dataSectionHeader.len], dataPtr
  add [rodataSectionHeader.offset], dataPtr

  sub rodataPtr, outRodata
  add rodataPtr, 0xfff
  and rodataPtr, ~0xfff
  mov [programRodataHeader.len], rodataPtr
  mov [rodataSectionHeader.len], rodataPtr

  ; output file
  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, fileHeader ; the header
  mov rdx, 0x1000 ; all of it
  syscall

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, outCode ; the code
  mov rdx, codePtr ; all of it
  syscall

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, outData ; the data
  mov rdx, dataPtr ; all of it
  syscall

  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  mov rsi, outRodata ; the rodata
  mov rdx, rodataPtr ; all of it
  syscall

  mov rdi, 0
  call exit

section .rodata
intcodeinit:
  jmp .end + 0x800

  times 0x800 - ($ - intcodeinit) nop
.end:
intcodepatch:
  shl r14, log2InstructionSize
  lea r14, [r14 + 0x401000]

  mov rax, 0
  cmp r15, 0
  cmovl r15, rax
  mov rax, r15
  mov rdx, 0
  mov r15, 100
  div r15
  mov r15, rdx
  
  shl r15, log2InstructionSize
  lea r15, [r15 + 0xc00000]

  mov rax, 10 ; mprotect
  mov rdi, r14
  and rdi, ~0xfff
  mov rsi, 0x1000
  mov rdx, 3 ; PROT_READ | PROT_WRITE
  syscall

  mov rdi, r14
  mov rsi, r15
  mov rcx, instructionSize
  rep movsb

  mov rax, 10 ; mprotect
  mov rdi, r14
  and rdi, ~0xfff
  mov rsi, 0x1000
  mov rdx, 5 ; PROT_READ | PROT_EXEC
  syscall

  jmp rbx

  times 0x800 - ($ - intcodepatch) nop
.end:

intcodeadd:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize
  
  mov r12, [0x800000 + 8 * (r15 + 1)]
  mov r13, [0x800000 + 8 * (r15 + 2)]
  mov r14, [0x800000 + 8 * (r15 + 3)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 10000
  div rdi
  cmp rax, 2
  jne .param3NotRelative

  add r14, r9
  jmp .doneParam3

.param3NotRelative:
.doneParam3:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r12, r9
  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  add r12, r13
  mov [0x800000 + 8 * r14], r12

  ; mov r14, r14
  mov r15, r12
  lea rbx, [rel .end + instructionSize * 3]
  mov rbp, 0x400800
  jmp rbp

  times instructionSize - ($ - intcodeadd) nop
.end:

intcodemul:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize
  
  mov r12, [0x800000 + 8 * (r15 + 1)]
  mov r13, [0x800000 + 8 * (r15 + 2)]
  mov r14, [0x800000 + 8 * (r15 + 3)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 10000
  div rdi
  cmp rax, 2
  jne .param3NotRelative

  add r14, r9
  jmp .doneParam3

.param3NotRelative:
.doneParam3:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r12, r9
  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  imul r12, r13
  mov [0x800000 + 8 * r14], r12

  ; mov r14, r14
  mov r15, r12
  lea rbx, [rel .end + instructionSize * 3]
  mov rbp, 0x400800
  jmp rbp

  times instructionSize - ($ - intcodemul) nop
.end:

intcodein:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize

  mov r14, [0x800000 + 8 * (r15 + 1)]
  mov r15, [0x800000 + 8 * (r15 + 0)]
  
  mov rax, r15
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r14, r9
  jmp .doneParam1

.param1NotRelative:
.doneParam1:

  mov rax, 0 ; read
  mov rdi, 0 ; from stdin
  lea rsi, [rsp - 8] ; to red zone buffer
  mov rdx, 8 ; 8 bytes
  syscall

  mov rax, [rsp - 8]
  mov [0x800000 + 8 * r14], rax

  ; mov r14, r14
  mov r15, rax
  lea rbx, [rel .end + instructionSize * 1]
  mov rbp, 0x400800
  jmp rbp

  times instructionSize - ($ - intcodein) nop
.end:

intcodeout:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize

  mov r14, [0x800000 + 8 * (r15 + 1)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r14, r9
  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  mov [rsp - 8], r14
  mov rax, 1 ; write
  mov rdi, 1 ; to stdout
  lea rsi, [rsp - 8] ; from red zone buffer
  mov rdx, 8 ; 8 bytes
  syscall

  jmp .end + instructionSize * 1

  times instructionSize - ($ - intcodeout) nop
.end:

intcodejnz:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize

  mov r13, [0x800000 + 8 * (r15 + 1)]
  mov r14, [0x800000 + 8 * (r15 + 2)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r14, r9
  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  test r13, r13
  jz .end + instructionSize * 2

  shl r14, log2InstructionSize
  add r14, 0x401000
  jmp r14

  times instructionSize - ($ - intcodejnz) nop
.end:

intcodejz:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize

  mov r13, [0x800000 + 8 * (r15 + 1)]
  mov r14, [0x800000 + 8 * (r15 + 2)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r14, r9
  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  test r13, r13
  jnz .end + instructionSize * 2

  shl r14, log2InstructionSize
  add r14, 0x401000
  jmp r14

  times instructionSize - ($ - intcodejz) nop
.end:

intcodelt:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize
  
  mov r12, [0x800000 + 8 * (r15 + 1)]
  mov r13, [0x800000 + 8 * (r15 + 2)]
  mov r14, [0x800000 + 8 * (r15 + 3)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 10000
  div rdi
  cmp rax, 2
  jne .param3NotRelative

  add r14, r9
  jmp .doneParam3

.param3NotRelative:
.doneParam3:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r12, r9
  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  mov rdi, 1
  cmp r12, r13
  mov r12, 0
  cmovl r12, rdi
  mov [0x800000 + 8 * r14], r12

  ; mov r14, r14
  mov r15, r12
  lea rbx, [rel .end + instructionSize * 3]
  mov rbp, 0x400800
  jmp rbp

  times instructionSize - ($ - intcodelt) nop
.end:

intcodeeq:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize
  
  mov r12, [0x800000 + 8 * (r15 + 1)]
  mov r13, [0x800000 + 8 * (r15 + 2)]
  mov r14, [0x800000 + 8 * (r15 + 3)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 10000
  div rdi
  cmp rax, 2
  jne .param3NotRelative

  add r14, r9
  jmp .doneParam3

.param3NotRelative:
.doneParam3:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 1000
  div rdi
  cmp rax, 2
  jne .param2NotRelative

  add r13, r9
  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotRelative:

  cmp rax, 0
  jne .param2NotPosition

  mov r13, [0x800000 + 8 * r13]

  jmp .doneParam2
.param2NotPosition:
.doneParam2:

  mov rax, rdx
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r12, r9
  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r12, [0x800000 + 8 * r12]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  mov rdi, 1
  cmp r12, r13
  mov r12, 0
  cmove r12, rdi
  mov [0x800000 + 8 * r14], r12

  ; mov r14, r14
  mov r15, r12
  lea rbx, [rel .end + instructionSize * 3]
  mov rbp, 0x400800
  jmp rbp

  times instructionSize - ($ - intcodeeq) nop
.end:

intcodesrel:
  lea r15, [rel $]
  sub r15, 0x401000
  shr r15, log2InstructionSize

  mov r14, [0x800000 + 8 * (r15 + 1)]
  mov r15, [0x800000 + 8 * (r15 + 0)]

  mov rax, r15
  mov rdx, 0
  mov rdi, 100
  div rdi
  cmp rax, 2
  jne .param1NotRelative

  add r14, r9
  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam1
.param1NotRelative:

  cmp rax, 0
  jne .param1NotPosition

  mov r14, [0x800000 + 8 * r14]

  jmp .doneParam1
.param1NotPosition:
.doneParam1:

  add r9, r14

  jmp .end + instructionSize * 1

  times instructionSize - ($ - intcodesrel) nop
.end:

intcodehalt:
  mov rax, 60 ; exit
  mov rdi, [0x800000]
  syscall

  times instructionSize - ($ - intcodehalt) nop
.end:

section .data
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
  dq 64 + 3 * 56 ; section header table pointer (after file and three program headers)
  dd 0 ; no flags
  dw 64 ; size of header
  dw 56 ; program header table entry size
  dw 3 ; program header table entry count
  dw 64 ; section header table entry size
  dw 4 ; section header table entry count
  dw 0 ; section header table entry index for section names
programTextHeader: ; sizeof (programTextHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 0x5 ; load as read/execute
  dq 0x1000 ; load from 0x1000 onwards
  dq 0x400000 ; load into entry point
  dq 0 ; don't care about physical address
.len:
  dq 0 ; load <textSize> bytes
  dq 0x400000 ; into 0x400000 bytes
  dq 0x1000 ; page-align
programDataHeader: ; sizeof (programDataHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 0x6 ; load as read/write
.offset:
  dq 0x1000 ; load from <textSize + 0x1000> onwards
  dq 0x800000 ; to address 0x800000
  dq 0 ; don't care about physical address
.len:
  dq 0 ; load <dataSize> bytes
  dq 0x400000 ; into 0x400000 bytes
  dq 0x1000 ; page-align
programRodataHeader: ; sizeof (programRodataHeader) = 56
  dd 1 ; this segment is to be loaded
  dd 0x4 ; load as read only
.offset:
  dq 0x1000 ; load from <textSize + dataSize + 0x1000> onwards
  dq 0xc00000 ; to address 0xc00000
  dq 0 ; don't care about physical address
.len:
  dq 0 ; load <rodataSize> bytes
  dq 0x400000 ; into 0x400000 bytes
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
.len:
  dq 0 ; from <textSize> bytes in the file
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0x1000 ; page-align
  dq 0 ; no entry size
dataSectionHeader: ; sizeof (dataSectionHeader) = 64
  dd 0 ; no name
  dd 1 ; program data
  dq 3 ; allocate space for section, writable section
  dq 0x800000 ; load into 0x800000
.offset:
  dq 0x1000 ; load from <textSize + 0x1000> onwards
.len:
  dq 0 ; from <dataSize> bytes in the file
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0x1000 ; page-align
  dq 0 ; no entry size
rodataSectionHeader: ; sizeof (dataSectionHeader) = 64
  dd 0 ; no name
  dd 1 ; program data
  dq 2 ; allocate space for section
  dq 0xc00000 ; load into 0xc00000
.offset:
  dq 0x1000 ; load from <textSize + dataSize + 0x1000> onwards
.len:
  dq 0 ; from <rodataSize> bytes in the file
  dd 0 ; no related section
  dd 0 ; no extra info
  dq 0x1000 ; page-align
  dq 0 ; no entry size
padding:
  db 0x1000 - ($ - fileHeader) dup 0 ; pad out to 0x1000 for start of program text

section .bss
outCode: resb 0x400000
outData: resb 0x400000
outRodata: resb 0x400000