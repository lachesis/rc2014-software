#!/bin/sh
fn=$(basename "${1}" .z80)
z80asm -b --output=${fn}.bin --origin=9000H ${fn}.z80
python2 bin2hex.py -r 2 -b 0x9000,${fn}.bin -o ${fn}.hex
#z80asm -b --output=${fn}.sim-bin --origin=0H ${fn}.z80  # for sim
cat ${fn}.hex | xclip -i
