# $Id: Makefile,v 1.2 2009/02/20 19:23:03 jrothwei Exp $
# Joseph Rothweiler, Started 16Feb2009.
# mcs51 device requires the Debian non-free sdcc-nf package.
#
all:  cy7c/usb_main.ihex cy7c/blinky.ihex

cy7c/%.ihex: %.c
	sdcc -Ifx2lib/include -mmcs51 -o$@ $<
