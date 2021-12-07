#!/usr/bin/env fish

set year (string split / (pwd))[-1]
../build.fish $argv[1]
and ../get-input.fish $year (string sub -l 1 $argv[1])
and ./$argv[1] (string sub -l 1 $argv[1]).txt