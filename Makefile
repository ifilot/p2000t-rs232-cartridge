all: src/BASIC-MODIFIED.bin

src/ollie.bin: src/ollie.asm
	z80asm src/ollie.asm -o src/ollie.bin

src/BASIC-MODIFIED.bin: src/ollie.bin src/build.py
	python3 src/build.py

clean:
	rm -rf src/ollie.bin src/BASIC-MODIFIED.bin
