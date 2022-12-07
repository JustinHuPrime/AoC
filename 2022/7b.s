extern mmap, exit, putlong, newline, alloc, findspace, findnl, atol

;; ASSUMES:
;;  - this is an pre-order traversal (maybe safe), i.e.:
;;  - we always start with '$ cd /'
;;  - we never cd more than one directory layer at a time (should be safe based
;;    on input spec)
;;  - we always run ls after a cd (is probably safe)
;;  - everything is inspected in alphabetical order

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap
  lea r15, [rax + 7] ; r15 = current character (skip first line)
  lea r14, [rax + rdx] ; r14 = end of input

  lea rdi, [rax + 5]
  lea rsi, [rax + 6]
  call strbcpy ; rax = "/"

  mov rdi, rax
  call newfolder

  mov r13, rax ; r13 = folder entry for "/"

  mov rdi, r13
  call parsefolder

  mov rsi, [r13 + 8] ; get current used size
  sub rsi, 70_000_000 - 30_000_000 ; may use at most 40 million bytes
  mov rdi, r13
  call findsmallest

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

;; struct treenode {
;;   char *name; // offset = 0
;;   qword size; // offset = 8
;;   union {
;;     struct {
;;       qword numentries; // offset = 16
;;       treenode **entries; // offset = 24
;;     } folder;
;;     struct {
;;     } file;
;;   } data;
;;   enum treenodetype : qword { // offset = 32
;;     FOLDER = 0;
;;     FILE = 1;
;;   } determinant;
;; }
;; sizeof(treenode) == 40

;; rdi = name
;; returns pointer to folder treenode
;; clobbers rsi, rdi, rcx, r11, rdx
newfolder:
  ; allocate folder
  mov rdx, rdi ; rdx = name
  mov rdi, 40 ; ; sizeof(treenode)
  call alloc

  mov [rax + 0], rdx ; set name
  mov QWORD [rax + 32], 0 ; set determinant

  ret

;; rdi = name
;; rsi = file size
;; returns pointer to file treenode
;; clobbers rsi, rdi, rcx, r11, rdx, r8
newfile:
  ; allocate file
  mov rdx, rdi ; rdx = name
  mov r8, rsi ; r8 = file size

  mov rdi, 40 ; sizeof(treenode)
  call alloc

  mov [rax + 0], rdx ; set name
  mov [rax + 8], r8 ; set file size
  mov QWORD [rax + 32], 1 ; set determinant

  ret

;; rdi = folder
;; rsi = number of entries
;; returns void
;; effect: allocates the specified number of entries for the folder
;; clobbers rsi, rdi, rcx, r11, rdx
sizefolder:
  mov rdx, rdi ; rdx = folder
  mov [rdx + 16], rsi ; save this->numentries
  lea rdi, [rsi * 8]
  call alloc
  mov [rdx + 24], rax ; store to this->entries
  ret

;; rdi = start of string
;; rsi = end of string
;; returns dynamically allocated null-terminated character string
;; clobbers rsi, rdi, rcx, r11, rdx, r8
strbcpy:
  mov rdx, rdi ; rdx = start of string
  mov r8, rsi ; r8 = end of string

  sub rsi, rdi ; rdi = length of string  + 1
  inc rsi
  mov rdi, rsi
  call alloc ; rax = string to return

  mov rcx, r8
  sub rcx, rdx ; rcx = length of string

  mov BYTE [rax + rcx], 0 ; add null terminator

  mov rsi, rdx ; copy string over from source
  mov rdi, rax
  rep movsb

  ret

;; rdi = allocated folder entry (as treenode *)
;; r15 = current character
;; r14 = end of input
;; returns void
;; clobbers SCRATCH
;; effects: fills in folder entry
parsefolder:
  ; consistency check - first four character must be "$ ls"
  cmp DWORD [r15], '$ ls'
  je .good
  int3 ; fail

.good:
  sub rsp, 8
  ;; stack slots:
  ;; rsp + 0 = this
  mov [rsp + 0], rdi

  add r15, 5 ; consume line with '$ ls' plus newline

  ; while *current != '$' && current != end
  mov r10, 0 ; r10 = count of entries
  mov rax, r15 ; rax = current character
.countEntryLoop:
  cmp BYTE [rax], '$'
  je .endCountEntryLoop
  cmp rax, r14
  je .endCountEntryLoop

  lea rdx, [r10 + 1]
  cmp BYTE [rax], 0xa
  cmove r10, rdx

  inc rax

  jmp .countEntryLoop
.endCountEntryLoop:

  mov rsi, r10
  call sizefolder

  ; for (r9 = 0; r9 < r10; ++r9)
  mov r9, 0
.parseEntryLoop:
  cmp r9, r10
  jnl .endParseEntryLoop

  cmp BYTE [r15], 'd'
  je .parseDir
  
  ; parsing file

  ; parse file size
  mov rdi, r15
  call findspace

  mov rdi, r15
  lea r15, [rax + 1] ; consume size plus space
  mov rsi, rax
  call atol

  push rax ; save file size

  ; parse file name
  mov rdi, r15
  call findnl

  mov rdi, r15
  lea r15, [rax + 1] ; consume name plus newline
  mov rsi, rax
  call strbcpy

  ; allocate file node
  mov rdi, rax
  pop rsi
  call newfile

  jmp .doneParse
.parseDir:

  ; parsing directory

  add r15, 4 ; consume "dir "

  ; parse directory name
  mov rdi, r15
  call findnl

  mov rdi, r15
  lea r15, [rax + 1] ; consume name plus newline
  mov rsi, rax
  call strbcpy

  mov rdi, rax
  call newfolder

.doneParse:

  ; node to list
  mov rdi, [rsp + 0]
  mov rdi, [rdi + 24] ; get this->entries
  mov [rdi + r9 * 8], rax

  inc r9

  jmp .parseEntryLoop
.endParseEntryLoop:

  ; for (r9 = 0; r9 < this->numentries; ++r9)
  mov r9, 0 ; r9 = current entry index
.finishEntryLoop:
  mov rdi, [rsp + 0] ; rdi = this
  cmp r9, [rdi + 16] ; get this->numentries
  jge .endFinishEntryLoop

  ; if this->entries[r9]->determinant == FOLDER
  mov rsi, [rdi + 24]
  mov rsi, [rsi + r9 * 8]
  bt QWORD [rsi + 32], 0
  jc .continueFinishEntryLoop

  ; skip "$ cd <foldername>"
  mov rdi, r15
  call findnl
  lea r15, [rax + 1]

  ; parse the folder
  mov rdi, [rsp + 0]
  mov rdi, [rdi + 24] ; get this->entries
  mov rdi, [rdi + r9 * 8]
  push r9
  call parsefolder
  pop r9

.continueFinishEntryLoop:

  inc r9

  jmp .finishEntryLoop
.endFinishEntryLoop:

  ; for (rsi = 0; rsi < this->numentries; ++rsi)
  mov rdi, [rsp + 0] ; rdi = this
  mov rdx, [rdi + 24] ; rdx = entries
  mov rsi, 0 ; rsi = current entry index
  mov rax, 0 ; rax = current size
.calculateSizeLoop:
  cmp rsi, [rdi + 16] ; get this->numentries
  je .endCalculateSizeLoop

  mov rcx, [rdx + rsi * 8] ; rcx = entry
  add rax, [rcx + 8] ; rax += entry->size

  inc rsi

  jmp .calculateSizeLoop
.endCalculateSizeLoop:

  mov [rdi + 8], rax ; store size

  add r15, 8 ; skip "$ cd .." + newline

  add rsp, 8
  ret

;; rdi = directory to traverse
;; rsi = minimum size to return
;; returns size of directory that is at least rsi
findsmallest:
  bt QWORD [rdi + 32], 0
  jc .fileReturn

  sub rsp, 16
  ;; stack slots
  ;; rsp + 0 = this
  ;; rsp + 8 = accumulator
  mov [rsp + 0], rdi
  mov QWORD [rsp + 8], -1

  ; for (rdx = 0; rdx < this->numentries; ++rdx)
  mov rdx, 0
.loop:
  mov rdi, [rsp + 0] ; rdi = this
  cmp rdx, [rdi + 16] ; rdx < this->numentries?
  jnl .endLoop

  push rdx
  mov rdi, [rdi + 24] ; rdi = this->entries
  mov rdi, [rdi + rdx * 8] ; rdi = this->entries[rdx]
  call findsmallest
  pop rdx

  ; if result is smaller than current result
  cmp rax, [rsp + 8]
  jnb .continue

  ; save it
  mov [rsp + 8], rax

.continue:

  inc rdx

  jmp .loop
.endLoop:

  ; fetch accumulator
  mov rax, [rsp + 8]

  ; if this->size < minimum size, return acc
  cmp [rdi + 8], rsi
  jb .return

  ; if this->size >= accumulator, return acc
  cmp [rdi + 8], rax
  jae .return

  mov rax, [rdi + 8] ; else return file

.return:

  add rsp, 16
  ret

.fileReturn:
  mov rax, -1
  ret