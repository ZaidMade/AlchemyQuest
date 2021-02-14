# Currently using Rednex v0.4.2
build: include/joypad.asm include/memory.asm src/*
	rgbasm -i include/ -i data/ -i src/ -o bin/out.o src/*
	rgblink -o bin/out.gb bin/out.o
	rgbfix -p0 -v bin/out.gb

# Replace this with the emulator of your choice:
run:
	/Applications/SameBoy.app/Contents/MacOS/Sameboy bin/out.gb
