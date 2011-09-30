# $Id: Makefile,v 1.7 2011/01/03 01:14:48 jrothwei Exp jrothwei $
# Copyright 2009 Joseph Rothweiler
# For GNU make

LIST = usb_opendev usb_writestring usb_readbytes kbhit_nowait \
       usb_int_readbytes usb_int_writestring usb_ctrl_msg

all: $(LIST:%=mex/%.mex)

oldstuff: mex/mex1.mex mex/firstmexdemo.mex mex/oct_myfunc.mex \
	mex/calltest.mex mex/my_mapfile.mex mex/my_mapped.mex \
	mex/my_mapread.mex

mex/%.mex: %.c
	mkdir -p mex
	# mkoctfile adds a huge number of library dependencies
	# to the mex-file (ldd shows them). --as-needed minimizes this.
	mkoctfile -Wall -Wl,--as-needed --mex -o $@ $< -lusb

# Remove intermediate files:
# Could just do: rm -vf $(LIST:%=%.o) , but this way avoids
# warnings without overriding protections.
clean:
	$(foreach x,$(LIST), test -e $x.o && rm -v $x.o;) true
