%define textSize 518

org 0

  db 0x7f,'ELF' ; magic number
  db 2 ; 64 bit format
  db 1 ; little endian
  db 1 ; version 1
  db 0 ; Unix/System V
  db 0 ; ignore ABI version
  db 7 dup 0 ; pad 7 bytes
  dw 0x2 ; executable
  dw 0x3e ; x86_64
  dd 1 ; version 1 again
  dq 0x401000 ; default entry point
  dq programHeader ; pointers to headers
  dq sectionHeader
  dd 0 ; no flags
  dw 64 ; size of this header
  dw 56 ; program header table entry size
  dw 2 ; program header table entry count
  dw 64 ; section header table entry size
  dw 3 ; section header table entry count
  dw 0 ; section header table entry index for section names
programHeader:
; text segment
  dd 0x1 ; segment to be loaded
  dd 0x5 ; load as RX
  dq end ; load following the headers
  dq 0x401000 ; load into entry point
  dq 0x401000
  dq textSize ; load <size> bytes
  dq textSize
  dq 0x1000 ; page-align
; bss segment
  dd 0x1 ; segument to be loaded
  dd 0x6 ; load as RW
  dq 0 ; not actually present
  dq 0x402000 ; load after program text
  dq 0x402000
  dq 0
  dq 0x1000 ; is a page of BSS
  dq 0x1000 ; page align
sectionHeader:
; null section
  db 64 dup 0
; text section
  dd 0 ; no name
  dd 0x1 ; text section
  dq 0x6 ; alloc | exec
  dq 0x401000 ; load into entry point
  dq end ; load following the headers
  dq textSize ; load <size> bytes
  dd 0 ; no associated section
  dd 0 ; no extra info
  dq 0x1000 ; page align
  dq 0 ; not fixed-size
; bss section
  dd 0 ; no name
  dd 0x8 ; bss
  dq 0x3 ; write | alloc
  dq 0x402000 ; load after text
  dq 0 ; not in file
  dq 0
  dd 0 ; no extra info
  dd 0
  dq 0x1000 ; page align
  dq 0 ; not fixed-size
end: