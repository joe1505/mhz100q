# $Id: Makefile,v 1.5 2009/07/02 21:24:46 jrothwei Exp $
# Copyright 2009 Joseph Rothweiler
# For GNU make

LIST = usb_opendev usb_writestring usb_readbytes kbhit_nowait

all: $(LIST:%=mex/%.mex)

oldstuff: mex/mex1.mex mex/firstmexdemo.mex mex/oct_myfunc.mex \
	mex/calltest.mex mex/my_mapfile.mex mex/my_mapped.mex \
	mex/my_mapread.mex

mex/%.mex: %.c
	mkdir -p mex
	mkoctfile -Wall --mex -o $@ $< -lusb

# Remove intermediate files:
# Could just do: rm -vf $(LIST:%=%.o)
clean:
	$(foreach x,$(LIST), test -e $x.o && rm -v $x.o;) true
