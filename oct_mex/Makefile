# $Id: Makefile,v 1.4 2009/06/17 18:18:45 jrothwei Exp $
# Copyright 2009 Joseph Rothweiler

all: \
	mex/usb_opendev.mex       \
	mex/usb_writestring.mex   \
	mex/usb_readbytes.mex

oldstuff: mex/mex1.mex mex/firstmexdemo.mex mex/oct_myfunc.mex \
	mex/calltest.mex

mex/%.mex: %.c
	mkdir -p mex
	mkoctfile -Wall --mex -o $@ $< -lusb
