#!/usr/bin/env fish

../build.fish $argv[1]
./$argv[1] (string sub -l 1 $argv[1]).txt