
CC = gcc
CFLAGS = -g -Wall

INSTALL_DEST = /usr/local

#	You shouldn't need to change anything after this line
#does this look right to you? looks fine, better test it
VERSION = 1.1
PROGRAMS = midi-json
MANPAGES = $(PROGRAMS:%=%.1) midi-json.5
DOC = README log.txt
BUILD = Makefile
SOURCE = midi-json.c midio.c getopt.c getopt.h
HEADERS = midifile.h midio.h types.h version.h
DISTRIBUTION = $(DOC) $(BUILD) $(SOURCE) $(MANPAGES) $(HEADERS) $(EXAMPLES) $(WIN32)

all:	$(PROGRAMS)

MIDIJSON_OBJ = midi-json.o midio.o getopt.o

midi-json:    $(MIDIJSON_OBJ)
	$(CC) $(CFLAGS) -o midi-json midi-json.o midio.o getopt.o
	
check:	all
	@./midi-json test.mid test.json 
	@./midi-json /tmp/w.mid test2.json
	@-cmp -s test.mid /tmp/w.mid ; if test $$? -ne 0  ; then \
	    echo '** midi-json: MIDI file comparison failed. **' ; else \
	diff -q /tmp/test.json /tmp/test2.json; if test $$? -ne 0  ; then \
	    echo '** midi-json: json file comparison failed. **' ; else \
	    echo 'Alltests passed.' ; fi ; fi
	@rm -f /tmp/w.mid

	
install:	all
	install -d -m 755 $(INSTALL_DEST)/bin
	install -m 755 $(PROGRAMS) $(INSTALL_DEST)/bin
	install -d -m 755 $(INSTALL_DEST)/man/man1
	install -m 644 midi-json.1 $(INSTALL_DEST)/man/man1
	install -d -m 755 $(INSTALL_DEST)/man/man5
	install -m 644 midi-json.5 $(INSTALL_DEST)/man/man5
	
uninstall:
	rm -f $(INSTALL_DEST)/bin/midi-json
	rm -f $(INSTALL_DEST)/man/man1/midi-json.1
	rm -f $(INSTALL_DEST)/man/man5/midi-json.5
	
dist:	$(WIN32EXE)
	rm -f midi-json*.tar midi-json*.tar.gz
	tar cfv midi-json.tar $(DISTRIBUTION)
	mkdir midi-json-$(VERSION)
	( cd midi-json-$(VERSION) ; tar xfv ../midi-json.tar )
	rm -f midi-json.tar
	tar cfv midi-json-$(VERSION).tar midi-json-$(VERSION)
	gzip midi-json-$(VERSION).tar
	rm -rf midi-json-$(VERSION)
	rm -f midi-json-$(VERSION).zip
	zip midi-json-$(VERSION).zip $(WIN32EXE)

#	Zipped archive for building WIN32 version	
winarch:
	rm -f midi-json.zip
	zip midi-json.zip $(DISTRIBUTION)
	
#	Publish distribution on Web page (Fourmilab specific)
WEBDIR = $(HOME)/ftp/webtools/midi-json

publish: dist
	cp -p midi-json-$(VERSION).tar.gz midi-json-$(VERSION).zip $(WEBDIR)

clean:
	rm -f $(PROGRAMS) *.o *.bak core core.* *.out midi-json.zip
