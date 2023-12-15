extern exit, mmap, putlong, newline, alloc

section .text

%define curr rbx
%define eof [rsp + 0]
%define label r12
%define focalLength bpl
%define entryPtrPtr r13
%define accumulator rdi
%define bucketIdx rbx
%define entryPtr rbp
%define lensIdx r12

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  sub rsp, 1 * 8
  ;; slots
  ;; rsp + 0 = eof/lastLine

  mov curr, rax
  add rax, rdx
  mov eof, rax

  ; follow instructions

.fileLoop:

  mov rdi, curr
  mov label, curr
.findLabelLoop:

  inc curr

  cmp BYTE [curr], '-'
  je .deleteLabel
  cmp BYTE [curr], '='
  je .setLabel
  jmp .findLabelLoop

.deleteLabel:

  mov rsi, curr
  call hash
  movzx rax, al

  mov rdi, label
  ; mov rsi, curr
  lea rdx, [hashmap + rax * 8]
  call findEntry
  mov entryPtrPtr, rax

  cmp QWORD [entryPtrPtr], 0
  je .continueDeleteLabel

  mov rdx, [entryPtrPtr]
  mov rdx, [rdx + 8]
  mov [entryPtrPtr], rdx

.continueDeleteLabel:

  add curr, 2 ; skip "-,"

  jmp .continueFileLoop
.setLabel:

  mov rsi, curr
  call hash
  movzx rax, al

  mov rdi, label
  ; mov rsi, curr
  lea rdx, [hashmap + rax * 8]
  call findEntry
  mov entryPtrPtr, rax

  mov focalLength, [curr + 1]
  sub focalLength, '0'

  cmp QWORD [entryPtrPtr], 0
  je .newLens

  mov rdx, [entryPtrPtr]
  mov [rdx + 7], focalLength

  jmp .continueSetLabel
.newLens:

  mov rdi, 16
  call alloc
  mov [entryPtrPtr], rax
  mov rdx, rax

  mov [rdx + 7], focalLength
  mov QWORD [rdx + 8], 0

  mov rdi, rdx
  mov rcx, 7
  mov al, 0
  rep stosb

  mov rdi, rdx
  mov rsi, label
  mov rcx, curr
  sub rcx, label
  rep movsb

.continueSetLabel:

  add curr, 3 ; skip "=#,"

  ; jmp .continueFileLoop
.continueFileLoop:

  cmp curr, eof
  jb .fileLoop

  ; calculate focusing power

  mov accumulator, 0
  mov bucketIdx, 0
.calculatePowerLoop:

  mov entryPtr, [hashmap + bucketIdx * 8]

  inc bucketIdx

  mov lensIdx, 1
.calculateBoxPowerLoop:
  cmp entryPtr, 0
  je .endCalculateBoxPowerLoop

  mov rax, bucketIdx
  mul lensIdx
  movzx rdx, BYTE [entryPtr + 7]
  mul rdx

  add accumulator, rax

  mov entryPtr, [entryPtr + 8]
  inc lensIdx

  jmp .calculateBoxPowerLoop
.endCalculateBoxPowerLoop:

  cmp bucketIdx, 256
  jb .calculatePowerLoop

  ; mov rdi, accumulator
  call putlong
  call newline

  mov dil, 0
  call exit

%define curr rdi
%define end rsi
%define value al
%define seventeen dl
;; rdi = start of string
;; rsi = end of string
;; returns hash of string
hash:
  mov seventeen, 17
  
  mov value, 0
.loop:
  ; get character and update hash
  add value, [curr]
  movzx ax, al
  mul seventeen

  inc curr

  cmp curr, end
  jb .loop

  ret

%undef value
%undef curr
%undef end
%undef seventeen

%define entryPtrPtr rax
%define entryPtr rdx
%define label rdi
%define endLabel rsi
%define entryLabel rcx
;; rdi = start of string
;; rsi = end of string
;; rdx = pointer to bucket
;; return pointer to pointer to found entry within the array, or
findEntry:
  mov entryPtrPtr, rdx

.loop:
  cmp QWORD [entryPtrPtr], 0
  je .end

  mov entryPtr, [entryPtrPtr]

  push label

  mov entryLabel, entryPtr
.checkEntryLoop:
  mov r8b, [entryLabel]
  cmp r8b, 0
  je .endCheckEntryLoop

  cmp [label], r8b
  jne .endCheckEntryLoop

  inc entryLabel
  inc label

  cmp label, endLabel
  jb .checkEntryLoop

  cmp BYTE [entryLabel], 0
  jne .endCheckEntryLoop

  ; found the entry!
  pop r8
  ret

.endCheckEntryLoop:

  ; didn't find the entry
  pop label
  lea entryPtrPtr, [entryPtr + 8]
  jmp .loop

.end:
  ret

%undef entryPtrPtr
%undef entryPtr

section .bss
;; hash map of boxes
;; struct BoxEntry {
;;   byte[7] label; // as null-terminated string
;;   byte focalLength;
;;   qword nextEntry;
;; }
hashmap: resq 256
