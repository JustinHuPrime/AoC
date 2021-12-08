section .text

extern writeNewline, writeLong, findWs, findChar

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

  mov r14, 0 ; r14 = sum so far

  mov rax, r15 ; rax = current position in file

  ; for each of the 200 lines
  mov rcx, 0
.readLineLoop:

  mov r10, rcx

  ; for each of the 10 hints
  mov rcx, 0
.readHintLoop:

  mov rdi, rax ; find the end of the hint
  call findWs

.readHintCharLoop: ; for each character within that hint

  mov sil, [rdi] ; get the character
  sub sil, 'a' ; convert to number
  movzx rsi, sil
  mov BYTE [hints + (rcx * 8) + rsi], 1 ; mark that character in the hint

  inc rdi ; next character

  cmp rdi, rax
  jl .readHintCharLoop

  inc rax ; next hint
  inc rcx

  cmp rcx, 10
  jl .readHintLoop

  add rax, 2 ; skip bar

  ; for each of the 4 result digits
  mov rcx, 0
.readResultLoop:

  mov rdi, rax ; find the end of the result
  call findWs

.readResultCharLoop: ; for each character within that result

  mov sil, [rdi] ; get the character
  sub sil, 'a' ; convert to number
  movzx rsi, sil
  mov BYTE [results + (rcx * 8) + rsi], 1 ; mark that character in the result

  inc rdi ; next character

  cmp rdi, rax
  jl .readResultCharLoop

  inc rax ; next result
  inc rcx

  cmp rcx, 4
  jl .readResultLoop

  mov r11, rax ; save state

  call solve ; solve the puzzle
  add r14, rax

  mov rcx, 10 * 8 + 4 * 8 + 10 ; clear the hints, results, and representations
  mov al, 0
  mov rdi, hints
  rep stosb

  mov rax, r11 ; restore state
  mov rcx, r10

  inc rcx
  cmp rcx, 200
  jl .readLineLoop

  mov rdi, r14
  call writeLong
  call writeNewline

  mov rax, 60 ; return 0
  mov rdi, 0
  syscall

;; given hints and results, solve the puzzle
;; returns result as an integer
;; clobbers as much as it's allowed to
solve:
  push rbx

  ; for each of the 10 hint values and four result values
  mov rcx, 14
.packLoop:
  mov al, 0

  or al, [hints + ((rcx - 1) * 8) + 0]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 1]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 2]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 3]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 4]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 5]
  shl al, 1
  or al, [hints + ((rcx - 1) * 8) + 6]

  mov [hints + ((rcx - 1) * 8) + 7], al

  loop .packLoop

  ; find the representation for 1, 4, 7, 8
  mov rdi, 2
  call findBits
  mov [representations + 1], al

  mov rdi, 3
  call findBits
  mov [representations + 7], al

  mov rdi, 4
  call findBits
  mov [representations + 4], al

  mov rdi, 7
  call findBits
  mov [representations + 8], al

  ; find the representation of the middle three horizontal lines
  mov bl, 0x7f ; bl = middle three hoizontal lines
  mov rcx, 0
.findMiddleLoop:
  mov dil, [hints + (rcx * 8) + 7]
  movzx rdi, dil
  popcnt rsi, rdi
  cmp rsi, 5
  jne .continueFindMiddleLoop

  and bl, dil

.continueFindMiddleLoop:
  
  inc rcx

  cmp rcx, 10
  jl .findMiddleLoop

  mov dil, bl
  or dil, [representations + 1]
  mov [representations + 3], dil ; 3 = 1 | middle 3

  mov dil, bl
  or dil, [representations + 4]
  mov [representations + 9], dil ; 9 = 4 | middle 3

  ; find the representation of zero
  ; 0 = that which has six segments but not all three middle ones
  mov rcx, 0
.findZeroLoop:

  mov dil, [hints + (rcx * 8) + 7]
  movzx rdi, dil
  popcnt rsi, rdi
  cmp rsi, 6
  jne .continueFindZeroLoop

  mov sil, dil
  and sil, bl
  cmp sil, bl
  je .continueFindZeroLoop

  mov [representations + 0], dil
  jmp .breakFindZeroLoop

.continueFindZeroLoop:

  inc rcx
  
  cmp rcx, 10
  jl .findZeroLoop
.breakFindZeroLoop:

  ; find the representation of six
  ; 6 = that which has six segments that's neither 0 nor 9
  mov rcx, 0
.findSixLoop:

  mov dil, [hints + (rcx * 8) + 7]
  movzx rdi, dil
  popcnt rsi, rdi
  cmp rsi, 6
  jne .continueFindSixLoop

  cmp dil, [representations + 0]
  je .continueFindSixLoop

  cmp dil, [representations + 9]
  je .continueFindSixLoop

  mov [representations + 6], dil
  jmp .breakFindSixLoop

.continueFindSixLoop:

  inc rcx

  cmp rcx, 10
  jl .findSixLoop
.breakFindSixLoop:

  ; find the representation of five
  ; 5 = that which has five segments that's not 3 and is a subset of 9
  mov rcx, 0
.findFiveLoop:

  mov dil, [hints + (rcx * 8) + 7]
  movzx rdi, dil
  popcnt rsi, rdi
  cmp rsi, 5
  jne .continueFindFiveLoop

  cmp dil, [representations + 3]
  je .continueFindFiveLoop

  mov sil, dil
  and sil, [representations + 9]
  cmp sil, dil
  jne .continueFindFiveLoop

  mov [representations + 5], dil
  jmp .breakFindFiveLoop

.continueFindFiveLoop:

  inc rcx

  cmp rcx, 10
  jl .findFiveLoop
.breakFindFiveLoop:

  mov dil, [representations + 5]
  not dil
  and dil, 0x7f
  or dil, bl
  mov [representations + 2], dil ; 2 = ~5 | middle 3

  ; convert the result digits into a number
  ; for each result digit
  mov rdi, 0
.resultToNumberLoop:

  mov al, [results + (rdi * 8) + 7] ; al = result digit

  ; for each of the 10 representations
  mov rsi, 0
.findRepresentationLoop:

  mov dl, [representations + rsi] ; dl = representation
  cmp al, dl
  je .breakFindRepresentationLoop

  inc rsi
  jmp .findRepresentationLoop
.breakFindRepresentationLoop:

  mov [results + (rdi * 8) + 7], sil ; save the converted value

  inc rdi

  cmp rdi, 4
  jl .resultToNumberLoop

  mov rdi, 10

  mov sil, BYTE [results + (0 * 8) + 7]
  movzx rax, sil

  imul rax, rdi

  mov sil, BYTE [results + (1 * 8) + 7]
  movzx rsi, sil
  add rax, rsi

  imul rax, rdi

  mov sil, BYTE [results + (2 * 8) + 7]
  movzx rsi, sil
  add rax, rsi

  imul rax, rdi

  mov sil, BYTE [results + (3 * 8) + 7]
  movzx rsi, sil
  add rax, rsi

  pop rbx

  ret

;; find the byte with the given popcnt result in the packed hints
;; assumes that byte always exist
;; rdi = popcnt result
;; returns byte with the given popcnt
;; clobbers rsi, rcx
findBits:
  mov rcx, 0
.loop:

  mov al, [hints + (rcx * 8) + 7]
  movzx rax, al
  popcnt rsi, rax
  cmp rdi, rsi
  je .return

  inc rcx

  jmp .loop

.return:
  ret

section .rodata

sizeOffset: equ 48
O_RDONLY: equ 0
PROT_READ: equ 1
MAP_PRIVATE: equ 2

section .bss

statBuf:
  resb 144
hints:
  ; list of seven 0/1 bytes, then the collected form of those bytes
  resb 10 * 8
results:
  resb 4 * 8
representations:
  resb 10