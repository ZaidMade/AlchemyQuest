build: inc/joypad.asm inc/memory.asm main.asm
	rgbasm -i include/ -i data/ -o bin/main.o src/main.asm
	rgblink -o bin/main.gb bin/main.o
	rgbfix -p0 -v bin/main.gb

run:
	/Applications/SameBoy.app/Contents/MacOS/Sameboy bin/main.gb