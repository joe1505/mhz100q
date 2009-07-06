$Id: README_SVN.txt,v 1.2 2009/07/06 19:15:54 jrothwei Exp jrothwei $
Copyright 2009 Joseph Rothweiler

Joseph Rothweiler
Sensicomm LLC
Hudson, NH, USA
http://www.sensicomm.com

This file started 15Apr2009.

**************** MHZ100Q ***************************

MHZ100Q is a collection of components for high-speed
data acquistion, including
- A 100MHz 8-bit quad A/D PCB design.
- VHDL code to capture data from the PCB.
- Firmware for a Cypress CY7C68013A USB interface.
- Drivers to access the USB interface from Octave
  and -eventually- from Matlab.

As of July 2009 the FPGA firmware supports digitizing
up to 4 channels at a 100 MHz sampling rate, optional
downsampling before storing into a 2k sample buffer,
and transfer of samples to an Octave program via USB.

Several useful features - such as triggering on
the waveform - are not yet implemented, and the
currently posted PCB hardware design requires some
minor modifications.

The project is hosted on Sourceforge and licensed
under the GPL. Some useful links:

http://mhz100q.sourceforge.net/             - Homepage.
http://www.sourceforge.net/projects/mhz100q - Project page.

Code is maintained in a Subversion repository.
To browse:
http://mhz100q.svn.sourceforge.net/viewvc/mhz100q/

Subversion download instructions are at:
http://sourceforge.net/scm/?type=svn&group_id=258218

Only the trunk subdirectory contains useful code.

For installation and test instructions, follow the
"Documentation" link on the homepage.

Test using the command: octave -q -i mhz100q.m
(by default, the program comes up in a test mode
which does not require the A/D converter PCB.)
To trigger a simulated conversion and display,
just hit the 't' key on the keyboard.
