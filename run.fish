#!/usr/bin/env fish

set year (string split / (pwd))[-1]
set day (string sub -l (math (string length $argv[1]) - 1) $argv[1])
../build.fish $argv[1]
and ../get-input.fish $year $day
and ./$argv[1] $day.txt