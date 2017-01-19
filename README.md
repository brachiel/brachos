# brachos
Bootloader playground

# Prerequisites
To run, you'll need a virtual machine; for example bochs or virtualbox.

$ apt-get install bochs bochs-sql

# Build

To build, simply:

make

Or, if you don't have make, you can use nasm directly after downloading it:

nasm -f bin -o brachos.img brachos.nasm

# Running

To run, mount brachos.img as a floppy and boot from it. Or use the bochs configuration file:

$ make run

or

$ bochs



