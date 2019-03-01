all:
	gcc -g -O0 -shared foo.c -o libfoo.so
	gcc -g -O0 usefoo.c -o usefoo -L. -lfoo -Wl,-rpath=$(shell pwd)

clean:
	rm -fv libfoo.so usefoo
