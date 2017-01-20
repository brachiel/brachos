# vim: set sw=4 tabstop=4 noexpandtab :

ASM=nasm

IMAGE=brachos.img

all: $(IMAGE)

%.img: %.asm
	${ASM} -f bin -o $@ $<

run: brachos.img
	bochs -q

clean:
	rm $(IMAGE)
	rmbochsout.txt
