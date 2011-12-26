CC = gcc

PYINCLUDE = /usr/include/python2.1/
RSINCLUDE = ./librsync/

DEFS = -DHAVE_CONFIG_H
CFLAGS=-O2 -fPIC -I$(PYINCLUDE) -I$(RSINCLUDE) $(DEFS)
LDFLAGS = -shared

main: rollsumc.so

rollsumc.so: rollsum_wrap.o rollsum.o
	gcc $(LDFLAGS) $^ -o $@

rollsum_wrap.c: rollsum.i
	swig -python -shadow $^

clean:
	rm -fv *.pyc *.o *.so rollsum.py *_wrap.doc *_wrap.c *~
