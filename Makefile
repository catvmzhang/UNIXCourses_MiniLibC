PRODEXE = ld -m elf_x86_64 --dynamic-linker /lib64/ld-linux-x86-64.so.2 -o $@ $< start.o -L. -L.. -lmini


libmini64.o: libmini64.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC $< -o $@

libmini.o: libmini.c libmini.h
	gcc -c -g -Wall -fno-stack-protector -fPIC -nostdlib $<

libmini.so: libmini64.o libmini.o
	ld -shared -o $@ $^

start.o : start.asm
	yasm -f elf64 -DYASM -D__x86_64__ -DPIC $< -o $@

%.o : %.c libmini.h
	gcc -c -g -Wall -fno-stack-protector -nostdlib -I. -I.. -DUSEMINI $<

alarm1 : alarm1.o start.o libmini.so
	$(PRODEXE)

alarm2: alarm2.o start.o libmini.so
	$(PRODEXE)

alarm3: alarm3.o start.o libmini.so
	$(PRODEXE)

jmp1: jmp1.o start.o libmini.so
	$(PRODEXE)

test: test.o start.o libmini.so
	$(PRODEXE)

clean:
	rm -f *.o *.so
