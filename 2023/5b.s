extern exit, mmap, putlong, newline, findws, atol, skipws, isnum, minlong

section .text

%define curr r12
%define arryPtr r13
%define mapPtr r13
%define endOfFile r14
%define endOfRanges r14

global _start:function
_start:
  mov rdi, [rsp + 16]
  call mmap

  ;; sub rsp, 0 * 8
  ;; slots
  ;; rsp + 0 = 

  mov curr, rax
  add rax, rdx
  mov endOfFile, rax

  ; read input

  ; skip "seeds: "
  add curr, 7
  mov arryPtr, seeds
  call readTextTerminatedNumbers

  ; skip "seed-to-soil map:\n"
  add curr, 18
  mov arryPtr, seedToSoilMap
  call readTextTerminatedNumbers

  ; skip "soil-to-fertilizer map:\n"
  add curr, 24
  mov arryPtr, soilToFertilizerMap
  call readTextTerminatedNumbers

  ; skip "fertilizer-to-water map:\n"
  add curr, 25
  mov arryPtr, fertilizerToWaterMap
  call readTextTerminatedNumbers

  ; skip "water-to-light map:\n"
  add curr, 20
  mov arryPtr, waterToLightMap
  call readTextTerminatedNumbers

  ; skip "light-to-temperature map:\n"
  add curr, 26
  mov arryPtr, lightToTemperatureMap
  call readTextTerminatedNumbers

  ; skip "temperature-to-humidity map:\n"
  add curr, 29
  mov arryPtr, temperatureToHumidityMap
  call readTextTerminatedNumbers

  ; skip "humidity-to-location map:\n"
  add curr, 26
  mov arryPtr, humidityToLocationMap
  call readEofTerminatedNumbers

  ; set endOfRanges
  ; do-while *endOfRanges != 0
  mov endOfRanges, seeds
.setEndOfRangesLoop:

  add endOfRanges, 16

  cmp QWORD [endOfRanges], 0
  jne .setEndOfRangesLoop

  ; apply mappings

  mov curr, seeds
  mov mapPtr, seedToSoilMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, soilToFertilizerMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, fertilizerToWaterMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, waterToLightMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, lightToTemperatureMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, temperatureToHumidityMap
  call applyMapToRange

  mov curr, seeds
  mov mapPtr, humidityToLocationMap
  call applyMapToRange

  ; collapse ranges to their first element
  mov curr, seeds
  mov arryPtr, seeds
  ; do-while *curr != 0
.collapseRangesLoop:
  mov rax, [curr]
  mov [arryPtr], rax

  add curr, 16
  add arryPtr, 8

  cmp QWORD [curr], 0
  jne .collapseRangesLoop

  mov rdi, seeds
  mov rsi, arryPtr
  call minlong

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

;; rdi = map
;; rsi = input range
;; uses endOfRanges
;; clobbers rsi, rdi, rdx
;; maps numbers in part of a range, appending to endOfRanges if there's any remainder
applyMapToElement:
  
  ; while map[2] != 0
.loop:
  cmp QWORD [rdi + 2 * 8], 0
  je .loopEnd
  
  ; check - is the input above or equal to the current source range start?
  mov rax, [rsi + 0]
  mov rdx, [rdi + 1 * 8]
  cmp rax, rdx
  jb .continueLoop
  ; check - is the input below sourceRangeStart + rangeLength
  add rdx, [rdi + 2 * 8]
  cmp rax, rdx
  jae .continueLoop

  ; do we need to split the range? (is b+d > a+c)
  add rax, [rsi + 8]
  cmp rax, rdx
  jbe .noSplitRange

  ; split range
  ; a..b..a+c..b+d
  ; if range 1 = a..a+c and range 2 = b..b+d
  ; length of current range = a+c - b
  ; start of new range = a+c
  ; length of new range = b+d - a+c

  ; start of new range = a+c
  mov [endOfRanges + 0], rdx

  ; length of new range = b+d - a+c
  sub rax, rdx
  mov [endOfRanges + 8], rax

  ; length of current range = a+c - b
  sub rdx, [rsi + 0]
  mov [rsi + 8], rdx

  add endOfRanges, 16

.noSplitRange:

  ; map the current range - destination = source - sourceRangeStart + destinationRangeStart
  mov rax, [rsi + 0]
  sub rax, [rdi + 1 * 8]
  add rax, [rdi + 0 * 8]
  mov [rsi + 0], rax
  jmp .loopEnd

.continueLoop:

  add rdi, 3 * 8

  jmp .loop
.loopEnd:

  ret

;; subroutine
;; uses curr
;; uses mapPtr
;; uses endOfRanges
;; maps numbers starting from curr until endOfRanges is reached
applyMapToRange:
  ; do-while curr < endOfRanges
  mov rdi, mapPtr
  mov rsi, curr
  call applyMapToElement

  add curr, 16

  cmp curr, endOfRanges
  jb applyMapToRange

  ret

;; subroutine
;; uses curr; ends pointed to start of next text
;; uses arryPtr
;; clobbers rdi, rsi, rax
readTextTerminatedNumbers:
  ; do-while current is a number
  ; read number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol
  mov [arryPtr], rax

  ; skip whitespace
  mov rdi, curr
  call skipws
  mov curr, rax

  add arryPtr, 8

  ; continue if this is a number
  mov dil, [curr]
  call isnum
  test al, al
  jnz readTextTerminatedNumbers

  ret

;; subroutine
;; uses curr; ends pointed to start of next text
;; uses arryPtr
;; uses endOfFile
;; clobbers rdi, rsi, rax
readEofTerminatedNumbers:
  ; do-while current is not EOF
  ; read number
  mov rdi, curr
  call findws
  mov rsi, rax
  mov curr, rax
  call atol
  mov [arryPtr], rax

  ; skip whitespace
  inc curr

  add arryPtr, 8

  ; continue if this is not EOF
  cmp curr, endOfFile
  jb readEofTerminatedNumbers

  ret

section .bss

;; struct mapEntry {
;;   qword destRangeStart;
;;   qword sourceRangeStart;
;;   qword rangeLength;
;; }
;; sizeof(mapEntry) = 3 * 8
seedToSoilMap: resq 128 * 3
soilToFertilizerMap: resq 128 * 3
fertilizerToWaterMap: resq 128 * 3
waterToLightMap: resq 128 * 3
lightToTemperatureMap: resq 128 * 3
temperatureToHumidityMap: resq 128 * 3
humidityToLocationMap: resq 128 * 3
;; struct seedsEntry {
;;   qword start;
;;   qword length;
;; }
seeds: resq 2 * 1024
