#!/bin/sh
z80asm -b --output=${1}.bin --origin=9000H ${1}.z80; python2 bin2hex.py -r 2 -b 0x9000,${1}.bin -o ${1}.hex; cat ${1}.hex | xclip -i
