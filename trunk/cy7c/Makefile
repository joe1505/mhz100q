# $Id: Makefile,v 1.2 2009/02/20 19:23:03 jrothwei Exp jrothwei $
# Copyright 2009 Joseph Rothweiler
# ---------------------------------------------------------
# Joseph Rothweiler, Started 16Feb2009.
# mcs51 device requires the Debian non-free sdcc-nf package.
# fx2lib is from fx2lib.wiki.sourceforge.net
#
all:  cy7c/usb_main.ihex cy7c/blinky.ihex

cy7c/%.ihex: %.c
	mkdir -p cy7c
	sdcc -Ifx2lib/include -mmcs51 -o$@ $<
