#!/usr/bin/env fish

curl -s --cookie (cat ../TOKEN) https://adventofcode.com/$argv[1]/day/$argv[2]/input > $argv[2].txt