section .text

extern writeNewline, writeLong, findChar, alloc

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

  mov rcx, 0 ; insert into links table both directions of the link
.readLoop:

  mov di, [r15] ; get first end of link
  mov [links + (rcx * (2+2) * 2) + 0], di
  mov [links + (rcx * (2+2) * 2) + 6], di

  lea rdi, [r15 + 2] ; skip to the dash
  mov sil, '-'
  call findChar
  lea r15, [rax + 1]

  mov di, [r15] ; get second end of link
  mov [links + (rcx * (2+2) * 2) + 2], di
  mov [links + (rcx * (2+2) * 2) + 4], di

  lea rdi, [r15 + 2] ; skip to the newline
  mov sil, 0xa
  call findChar
  lea r15, [rax + 1]

  inc rcx

  cmp rcx, 26
  jl .readLoop

  mov di, [st]
  mov rsi, 0
  call countPaths

  mov rdi, rax
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; di = current link id
;; rsi = linked list of vistied links
;; returns number of paths to 'en' link
;; clobbers everything
countPaths:
  push r12 ; r12w = current link id
  mov r12w, di
  push r13 ; r13 = linked list of visited links
  mov r13, rsi
  push r14 ; r14 = linked list of connected nodes (initialized later)
  push r15
  mov r15, 0 ; r15 = return value

  call cannotVisit
  test rax, rax
  mov rdx, 0
  cmovnz rax, rdx
  jnz .done

  cmp r12w, [en]
  mov rdx, 1
  cmove rax, rdx
  je .done

  mov rdi, 16 ; r13 = (cons node path)
  call alloc
  mov [rax + 0], r12w
  mov [rax + 8], r13
  mov r13, rax

  mov di, r12w
  call findLinks
  mov r14, rax

  ; for each link in the linked list (at least one, since we got here)
.linkLoop:
  mov di, [r14 + 0]
  mov rsi, r13
  call countPaths
  add r15, rax

  mov r14, [r14 + 8] ; next node in the linked list

  test r14, r14
  jnz .linkLoop

  mov rax, r15

.done:
  pop r15
  pop r14
  pop r13
  pop r12
  ret

;; di = current link id
;; rsi = linked list of visited links
;; clobbers everything
cannotVisit:
  push r10 ; r10w = current link id
  mov r10w, di
  push r11 ; r11 = linked list of visited links
  mov r11, rsi

  ; is this uppercase? (i.e. less than 'Z'?)
  mov rdx, 0
  cmp r10b, 'Z'
  cmovbe rax, rdx
  jbe .done

  ; is this a member of the path?
  mov rdx, 1
  mov rax, 0
.loop:
  test r11, r11
  jz .done

  cmp r10w, [r11 + 0]
  cmove rax, rdx
  je .done

  mov r11, [r11 + 8]

  jmp .loop

.done:
  pop r11
  pop r10
  ret

;; di = current link id
;; clobbers everything
findLinks:
  push r15 ; r15 = return value
  mov r15, 0
  push r14 ; r14 = link list index
  mov r14, 0
  push r13 ; r13 = current link id
  mov r13w, di

  ; for each link in the table
.loop:
  cmp r13w, [links + (r14 * (2+2)) + 0]
  jne .continue

  mov rdi, 16
  call alloc
  mov [rax + 8], r15
  mov r15, rax
  mov di, [links + (r14 * (2+2)) + 2]
  mov [r15 + 0], di

.continue:

  inc r14

  cmp r14, 26*2
  jl .loop

  mov rax, r15

  pop r13
  pop r14
  pop r15
  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2
st:
  db 'st'
en:
  db 'en'

section .bss

statBuf:
  resb 144
;; struct link {
;;   char[2] from;
;;   char[2] to;
;; }
links:
  resb 26*2*(2+2)