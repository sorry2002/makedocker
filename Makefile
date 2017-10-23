PREFIX:=/usr/local
BINDIR:=/bin
DATADIR:=/share

all: clean makedocker
	
makedocker: makedocker.sh
	sed -e 's|@PREFIX@|${PREFIX}|g' \
	    -e 's|@DATADIR@|${DATADIR}|g' < $^ > $@

install: makedocker template
	install makedocker ${PREFIX}${BINDIR}/makedocker
	mkdir -pv ${PREFIX}${DATADIR}/makedocker
	cp -v template ${PREFIX}${DATADIR}/makedocker/

uninstall:
	rm -vf ${PREFIX}${BINDIR}/makedocker
	rm -rvf ${PREFIX}${DATADIR}/makedocker

clean:
	rm -vf makedocker
