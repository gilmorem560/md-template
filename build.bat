@ECHO OFF

asm68k -e -c -- main.s | makerom > rom.bin

echo Build Complete!