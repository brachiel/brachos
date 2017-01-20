# brachos
Bootloader playground

# Prerequisites
To run, you'll need a virtual machine; for example bochs or virtualbox.

$ apt-get install bochs bochs-sdl

To run the debugger, you might have to recompile bochs yourself. There's some bugs in the current configure script of bochs, so here's how we did it:

$ ./configure --enable-debugger --enable-disasm --enable-debugger-gui --without-x --without-x11 --without-beos --without-win32 --without-macos --without-carbon --with-nogui --with-term --without-rfb --without-amigaos --with-sdl --without-svga --without-wx LDFLAGS='-pthread'

This will configure and compile bochs with only the sdl GUI and enabled gui debugger. The LDFLAGS circumvents the mentioned bug in configure.

# Build

To build, simply:

$ make

Or, if you don't have make, you can use nasm directly after downloading it:

$ nasm -f bin -o brachos.img brachos.nasm

# Running

To run, mount brachos.img as a floppy and boot from it. Or use the bochs configuration file:

$ make run

or

$ bochs

# How it works

The BIOS looks at the first 512 bytes of each configured bootable device. It copies the bytes into physical memory starting at 0x7c00. If the last two bytes are 0x55,0xaa the bootsector is considered valid and execution starts at 0x7c00.

