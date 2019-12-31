# md-template

    A simple Megadrive game template that may grow into a project. This code
targets the asmx suite of assemblers. To build, simply run the appropriate
build script located in the root folder. Be sure that asm68k, asmz80, and
makerom are in your PATH variable or otherwise are placed in the same root
folder as the build scripts and main.s

# Addition of new features

    New code should be added to/INCLUDE'd in main.s. This file currently then
calls the ICD_BLK4 standard system init routine and then the LOCK regional
lockout code.