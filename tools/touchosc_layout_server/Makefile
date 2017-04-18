CC = c99
CFLAGS = -Wall -O2

# LIB = -lpthread

PREFIX ?= /usr/local
INSTALLDIR ?= $(PREFIX)/bin

all: tosrv

tosrv: tosrv.c
	$(CC) $(CFLAGS) -o tosrv tosrv.c $(LIB)

install:
	mkdir -p $(INSTALLDIR)
	install -m755 tosrv $(INSTALLDIR)

uninstall:
	-rm -f $(INSTALLDIR)/tosrv

clean:
	rm -f *.o tosrv *~
