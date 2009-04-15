# $Id: Makefile,v 1.1 2009/04/15 14:56:06 jrothwei Exp jrothwei $
# Copyright 2009 Joseph Rothweiler

all: mex1.mex firstmexdemo.mex oct_myfunc.mex \
	usb_opendev.mex       \
	usb_writestring.mex   \
	usb_readbytes.mex

%.mex: %.c
	 mkoctfile --mex $< -lusb
