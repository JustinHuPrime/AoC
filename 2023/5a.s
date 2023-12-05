extern exit, mmap, putlong, newline, findws, atol, skipws, isnum, minlong

section .text

%define curr r12
%define arryPtr r13
%define mapPtr r13
%define endOfFile r14

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

  ; find smallest
  mov rdi, seeds
  mov rsi, seeds
.findEndLoop:
  cmp QWORD [rsi], 0
  je .findEndLoopEnd

  add rsi, 8

  jmp .findEndLoop
.findEndLoopEnd:

  call minlong

  mov rdi, rax
  call putlong
  call newline

  mov dil, 0
  call exit

;; subroutine
;; uses curr
;; uses mapPtr
;; maps numbers starting from curr until a zero
applyMapToRange:
  ; do-while *curr != 0
  mov rdi, mapPtr
  mov rsi, [curr]
  call applyMapToElement
  mov [curr], rax

  add curr, 8

  cmp QWORD [curr], 0
  jne applyMapToRange

  ret


;; rdi = map
;; rsi = input id
;; clobbers rdi, rsi
;; returns mapped-to value
applyMapToElement:
  mov rax, rsi

  ; while map[2] != 0
.loop:
  cmp QWORD [rdi + 2 * 8], 0
  je .loopEnd

  ; check - is the input above or equal to the current source range start?
  mov rsi, [rdi + 1 * 8]
  cmp rax, rsi
  jb .continueLoop
  ; check - is the input below sourceRangeStart + rangeLength
  add rsi, [rdi + 2 * 8]
  cmp rax, rsi
  jae .continueLoop

  ; valid mapping - destination = source - sourceRangeStart + destinationRangeStart
  sub rax, [rdi + 1 * 8]
  add rax, [rdi + 0 * 8]
  jmp .loopEnd

.continueLoop:
  
  add rdi, 3 * 8

  jmp .loop
.loopEnd:
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

seeds: resq 32
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
