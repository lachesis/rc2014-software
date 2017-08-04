#!/bin/sh
TASM_PATH=~/build/z80/tasm
ln -s $TASM_PATH/TASM.EXE .
ln -s $TASM_PATH/TASM80.TAB .

basefn=$(basename $1 .asm)

cat > b.bat <<EOF
tasm -80 -a7 -fff -c -l d:${basefn}.asm d:${basefn}.hex
EOF
dosemu b.bat

rm b.bat
rm TASM.EXE TASM80.TAB

cat ${basefn}.hex | xclip -i

